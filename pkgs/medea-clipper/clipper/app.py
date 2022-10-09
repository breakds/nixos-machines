import click
import pyperclip
from loguru import logger
from bottle import route, run, view, post, request, redirect, static_file

ENTRIES = []

@click.group()
def main():
    logger.info("Welcome to Medea Clipper")

@main.command()
@click.option(
    "--port", default=33337, type=click.INT, help="Specify the port of the app"
)
def serve(port):
    logger.info("Start running server at 0.0.0.0:{port}", port=port)
    run(host="0.0.0.0", port=port)

@post("/add")
def add():
    ENTRIES.append(request.forms.getunicode("content"))
    redirect("/")

@route("/copy/<idx>")
def copy(idx):
    idx = int(idx)
    pyperclip.copy(ENTRIES[idx])
    redirect("/")

@route("/")
@view("app")
def index():
    a = 5
    return {
        "entries": [(idx, entry) for idx, entry in enumerate(ENTRIES)]
    }

if __name__ == "__main__":
    main()
