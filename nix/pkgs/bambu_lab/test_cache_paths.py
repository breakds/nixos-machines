"""Exercise the upload handler without importing or starting Home Assistant."""

import ast
import asyncio
import logging
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import AsyncMock

from aiohttp import web
import pytest


@pytest.fixture
def upload(tmp_path):
    # Upstream's tests import pybambu alone. Load the actual handler body with
    # only its HA base class stubbed, so these checks need no running HA instance.
    source = Path(__file__).parents[1] / "custom_components/bambu_lab/__init__.py"
    tree = ast.parse(source.read_text())
    handler = next(node for node in tree.body
                   if isinstance(node, ast.ClassDef) and node.name == "EnsureCacheFileAPIView")
    namespace = {
        "HomeAssistantView": object,
        "HomeAssistant": object,
        "Path": Path,
        "web": web,
        "DOMAIN": "bambu_lab",
        "LOGGER": logging.getLogger(__name__),
    }
    exec(compile(ast.Module(body=[handler], type_ignores=[]), str(source), "exec"), namespace)

    cache = tmp_path / "www/media/ha-bambulab"
    for serial in ("TARGET", "SOURCE"):
        (cache / serial / "prints/cache").mkdir(parents=True)
        (cache / serial / "prints/cache/model.3mf").write_text("dummy print")
    (tmp_path / ".storage").mkdir()
    secret = tmp_path / ".storage/auth"
    secret.write_text("dummy credentials")
    job = SimpleNamespace(
        async_ftp_file_check=AsyncMock(return_value=False),
        async_ftp_upload_file=AsyncMock(return_value=True),
    )
    model = SimpleNamespace(info=SimpleNamespace(serial="TARGET"), print_job=job)
    coordinator = SimpleNamespace(
        get_model=lambda: model,
        get_file_cache_directory=lambda: str(cache / "TARGET"),
    )
    hass = SimpleNamespace(data={"bambu_lab": {"entry": coordinator}})
    view = namespace["EnsureCacheFileAPIView"](hass)

    def request(path):
        return asyncio.run(view.post(SimpleNamespace(json=AsyncMock(return_value={
            "serial": "TARGET", "cache_path": path, "expected_size": 11,
        }))))

    return SimpleNamespace(request=request, job=job, cache=cache, secret=secret)


@pytest.mark.parametrize("serial", ["TARGET", "SOURCE"])
def test_upload_from_printer_cache(upload, serial):
    path = f"{serial}/prints/cache/model.3mf"
    assert upload.request(path).status == 200
    upload.job.async_ftp_file_check.assert_awaited_once_with("/cache/model.3mf", 11)
    assert upload.job.async_ftp_upload_file.await_args.args == (
        str(upload.cache / path), "/cache/model.3mf",
    )


@pytest.mark.parametrize("path", [
    "TARGET/prints/../../../../../.storage/auth",
    "../TARGET/prints/cache/model.3mf",
    "TARGET/prints/cache/../model.3mf",
    "/TARGET/prints/cache/model.3mf",
    "TARGET/timelapse/model.3mf",
    "TARGET/prints",
    ["TARGET", "prints", "model.3mf"],
])
def test_invalid_path_rejected_before_ftp(upload, path):
    assert upload.request(path).status == 400
    upload.job.async_ftp_file_check.assert_not_awaited()
    upload.job.async_ftp_upload_file.assert_not_awaited()


def test_absolute_path_to_config_rejected(upload):
    path = str(upload.cache / "TARGET/prints/../../../../../.storage/auth")
    assert upload.request(path).status == 400
    upload.job.async_ftp_file_check.assert_not_awaited()
    upload.job.async_ftp_upload_file.assert_not_awaited()


def test_source_symlink_escape_rejected(upload):
    (upload.cache / "SOURCE/prints/auth").symlink_to(upload.secret)
    assert upload.request("SOURCE/prints/auth").status == 403
    upload.job.async_ftp_file_check.assert_not_awaited()
    upload.job.async_ftp_upload_file.assert_not_awaited()


def test_destination_symlink_escape_rejected(upload):
    destination = upload.cache / "TARGET/prints/cache/model.3mf"
    destination.unlink()
    destination.symlink_to(upload.secret)
    assert upload.request("SOURCE/prints/cache/model.3mf").status == 403
    upload.job.async_ftp_file_check.assert_not_awaited()
    upload.job.async_ftp_upload_file.assert_not_awaited()
    assert upload.secret.read_text() == "dummy credentials"
