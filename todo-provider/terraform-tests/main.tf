terraform {
  required_providers {
    todo = {
      source  = "spkane/todo"
      version = "1.2.3"
      # loads from https://registry.terraform.io/providers/spkane/todo/1.2.3
    }
  }
}

# no backend provided, so it will create a local tfstate file
# (ok for local dev/testing, bad for any kind of a shared environment)

provider "todo" {
  host = "todo-api.spkane.org"
  # below are default values so don't really have to set them, but here as example
  port = "8080"
  apipath = "/"
  schema = "http"
}

# reads an object, not manage it
# this will read todo obj w/id of 11 (todo-api.spkane.org/api/todos/11 - or whatever)
data "todo" "foreign" {
  id = 11
}

# if this could not be found returns:
# $ terraform plan
# data.todo.foreign: Reading...
# ╷
# │ Error: [GET /{id}][500] findTodo default  &{Code:500 Message:0xc0005abfc0}
# │
# │   with data.todo.foreign,
# │   on main.tf line 24, in data "todo" "foreign":
# │   24: data "todo" "foreign" {


resource "todo" "test1" {
  count = 5 # this will create 5 of these, in an array
            # named test1[0], test1[1], test1[2], test1[3], test1[4]
  description = "${count.index}-1 ${var.purpose} todo"
  completed = false
}

resource "todo" "test2" {
  count = 5
  description = "${count.index}-2 ${var.purpose} todo (linked to ${data.todo.foreign.description})"
  completed = false
}



### using a module ###

module "series-data" {
  source       = "../modules/todo-test-data"
  number       = 5
  purpose      = "testing"
  team_name    = "oreilly"
  descriptions = ["my first completed todo", "my second completed todo",
                  "my third completed todo", "my fourth completed todo",
                  "my fifth completed todo"
                 ]
}