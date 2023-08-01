import click
from lark import Lark


@click.group()
def app():
    pass


ERROR_PARSER = Lark(r"""
    error : "Expected:" INT "arrays" object ", Got:" INT "arrays" object "."?
    object : CNAME ["(" kv1 ("," kv1)*] ")"
    kv1 : CNAME "=" value
    value : object | dict | tuple | nparray | accessor
    number : NUMBER | SIGNED_NUMBER
    tuple : "(" [number ("," number)* ","?] ")"
    nparray : "array(" (array | number) ("," kv1)* ")"
    array : "[" array_element ["," array_element ]* "]"
    array_element: number | array
    kv2 : STR ":" value
    dict : "{" [kv2 ("," kv2)*] "}"
    STR : "'" (LETTER | "_" | "@" | "/")* "'"
    accessor : CNAME ("." CNAME)*

    %import common.INT
    %import common.NUMBER
    %import common.SIGNED_NUMBER
    %import common.CNAME
    %import common.LETTER
    %import common.WS
    %ignore WS
""", start="error")


NEST_PARSER = Lark(r"""
    nest : object | dict
    object : CNAME ["(" kv1 ("," kv1)*] ")"
    kv1 : CNAME "=" value
    value : object | dict | tuple | nparray | accessor
    number : NUMBER | SIGNED_NUMBER
    tuple : "(" [number ("," number)* ","?] ")"
    nparray : "array(" (array | number) ("," kv1)* ")"
    array : "[" array_element ["," array_element ]* "]"
    array_element: number | array
    kv2 : STR ":" value
    dict : "{" [kv2 ("," kv2)*] "}"
    STR : "'" (LETTER | "_" | "@" | "/")* "'"
    accessor : CNAME ("." CNAME)*

    %import common.INT
    %import common.NUMBER
    %import common.SIGNED_NUMBER
    %import common.CNAME
    %import common.LETTER
    %import common.WS
    %ignore WS
""", start="nest")


def print_object(x, indent: int = 0):
    if x.data.value == "object":
        name = x.children[0]
        if name.value in ["TensorSpec", "BoundedTensorSpec"]:
            print(f"{name}()")
            return
        print(f"{name}(")
        for y in x.children[1:]:
            print_object(y, indent + 2)
        print(f"{' ' * (indent - 2)})")
    elif x.data.value == "kv1":
        key = x.children[0]
        print(f"{' ' * indent}{key} = ", end="")
        print_object(x.children[1].children[0], indent + 2)
    elif x.data.value == "dict":
        print("{")
        for y in x.children:
            print_object(y, indent + 2)
        print(f"{' ' * (indent - 2)}", end="")
        print("}")
    elif x.data.value == "kv2":
        key = x.children[0]
        print(f"{' ' * indent}{key}: ", end="")
        print_object(x.children[1].children[0], indent + 2)
    else:
        print("...")


@app.command
@click.argument("path", type=str)
def scan(path: str):
    with open(path, "r") as f:
        text = f.read()
    ast = ERROR_PARSER.parse(text)
    print(f"---------- {ast.children[0]} items ----------")
    print_object(ast.children[1])
    print(f"---------- {ast.children[2]} items ----------")
    print_object(ast.children[3])


@app.command
@click.argument("path", type=str)
def print_nest(path: str):
    with open(path, "r") as f:
        text = f.read()
    ast = NEST_PARSER.parse(text)
    print_object(ast.children[0])


if __name__ == "__main__":
    app()
