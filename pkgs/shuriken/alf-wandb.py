import socket
import subprocess
from pathlib import Path
import json
import tempfile
import wandb
import click
from loguru import logger

HOST_INFO = {
    "malenia": {
        "location": "homelab",
        "session_root": "dataset",
    },

    "lorian": {
        "location": "homelab",
        "session_root": "tmp",
    },

    "lothric": {
        "location": "homelab",
        "session_root": "tmp",
    },

    "samaritan": {
        "location": "lab",
        "session_root": "dataset",
    },

    "GAIL3": {
        "location": "lab",
        "session_root": "tmp",
    },
}


class MetaData(object):
    def __init__(self, run):
        directory = tempfile.gettempdir()
        run.file("wandb-metadata.json").download(root=directory, replace=True)
        self.path = Path(directory, "wandb-metadata.json")
        logger.success(
            f"Metadata file downloaded at {self.path}")
        with open(self.path, "r") as f:
            self.full = json.load(f)

        self.host = self.full["host"]
        for i in range(len(self.full["args"])):
            if self.full["args"][i] == "--root_dir":
                self.root_dir = Path(self.full["args"][i+1])
                break


def reference_remote_host(remote_host, local_host):
    if HOST_INFO[local_host]["location"] == "homelab":
        if HOST_INFO[remote_host]["location"] == "homelab":
            return f"{remote_host}.local"
        else:
            return f"into-{remote_host.lower()}"
    else:
        if HOST_INFO[remote_host]["location"] == "homelab":
            return f"into-{remote_host}"
        else:
            return remote_host.lower()


def compute_local_directory(remote_root_dir, local_host):
    d = remote_root_dir
    while d.name != "alf_sessions":
        d = d.parent
    relative_path = remote_root_dir.relative_to(d)
    return Path(f"/home/breakds{HOST_INFO[local_host]['session_root']}"
                "/alf_sessions", relative_path)


def sync_root_dir(host, source):
    local_host = socket.gethostname()

    ref_host = reference_remote_host(host, local_host)
    logger.info(f"Fetching from: {ref_host}:{source}")

    local_directory = compute_local_directory(source, local_host)
    logger.info(f"Syncing to {local_directory} ...")
    local_directory.parent.mkdir(parents=True, exist_ok=True)

    subprocess.run([
        "rsync", "-av", "--info=progress2",
        f"{ref_host}:{source}",
        f"{local_directory.parent}"])

    logger.info(f"Find synced root dir at {local_directory}")
    logger.success("Syncing is done.")


@click.group()
def app():
    pass


@app.command()
@click.argument("run_id", type=str)
@click.option("-e", "--entity", type=str, default="horizon-robotics-gail")
def sync(run_id, entity):
    api = wandb.Api()
    logger.success("Wandb API initialized.")

    target = None
    for project in api.projects(entity=entity):
        project_path = "/".join(project.path)
        logger.info(f"Searching in project {project_path} ...")
        for run in api.runs(project_path):
            if run.path[-1] == run_id:
                logger.success(
                    f"Found specified run at project {project_path}")
                target = run
                break
        if target is not None:
            break

    metadata = MetaData(target)
    sync_root_dir(metadata.host, metadata.root_dir)


if __name__ == "__main__":
    app()
