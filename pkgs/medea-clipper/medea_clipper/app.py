import click
import os
import pyperclip
from loguru import logger
from bottle import route, run, template, post, request, redirect, static_file

ENTRIES = []

APP_TPL = """
<link rel="stylesheet" href="https://unpkg.com/@picocss/pico@latest/css/pico.min.css">

<main class="container">

  <form action="/add" method="post">
    <div class="grid">
      <label for="content">
        Input:
        <input name="content" id="content" type="text" placeholder="..."/>
      </label>
      <button type="submit">Submit</button>
    </div>
  </form>

  <table>
    <thead>
      <tr>
        <th>Text</th>
        <th>Action</th>
      </tr>
    </thead>
    <tbody>
      % for idx, item in entries:
      <tr>
        <td>{{item}}</td>
        <td>
          <a href="/copy/{{idx}}">
            <button type="button">Copy</button>
          </a>
        </td>
      </tr>
      % end
    </tbody>
  </table>
</main>
"""

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
def index():
    a = 5
    return template(
        APP_TPL,
        entries=[(idx, entry) for idx, entry in enumerate(ENTRIES)])


if __name__ == "__main__":
    logger.info("haha!")
    logger.info(os.getenv("PATH"))
    main()
