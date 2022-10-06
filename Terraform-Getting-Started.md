# O'Reilly Terraform Training

[Terraform: Getting Started](https://learning.oreilly.com/live-events/terraform-getting-started/0636920060088/0636920076176/)

Sean P Kane
<br>[@spkane](https://twitter.com/spkane)
<br>@superorbital_io

10/6/2022

[Slides](classterraformgetstarted31664810606616.pdf)
<br>[Gist of slides](https://gist.github.com/spkane/df02f7858f6bef9f045fa1c296f8146f)


## Instructor environment

Shell prompt (shows Git info, etc) - [Starship](https://starship.rs)
<br>Console font - [Fira Code](https://github.com/tonsky/FiraCode)
<br>VS Code


## Notes

Will be creating a custom provider - the Todo provider that allows you to create reminders and indicate if they are completed or not.

https://github.com/spkane/todo-for-terraform


Terraform is a tool that makes it possible to document and automate the creation, modification, and destruction of _almost anything that can be managed by an API_. (emphasis mine)
* At the end of the day, TF is a tool that knows how to talk to APIs


Tool - [tfenv](https://github.com/tfutils/tfenv) - manage different versions of TF (say if different projects are using different versions)


Typical commands:
* `tf init`
* `tf plan`
* `tf apply`

After apply:
* `tf outputs`
* `tf state list`
* `tf state pull`


Core components:
* Terraform & Backends
* Providers
* Variables
* Resources
* Functions
* Data Sources
* Outputs
* State File


```hcl
resource "resource_type" "resource_name" {
  variable1 = value1
  variable2 = value2

  object1 = {
    objvariable1 = objvalue1
    objvariable2 = objvalue2
  }
}
```
^ think about this as parameters to a REST API

Calling the `resource_type` API, converting the body to a JSON payload, and naming the result `resource_name`.

_(I think I heard it like that.)_ :thinking_face:


Providers == plugins
- wrappers to APIs you want to interact with

`hashicorp/external` - special case
* provider that doesn't interact with an API, but allows you to run a local script and get data back (such as a local IP)


Functions
```hcl
public_key = file(var.ssh_public_key_path)
```


Data sources (data objects) are read-only


```bash
$ http todo-api.spkane.org:8080
```

```bash
$ http POST todo-api.spkane.org:8080 "Content-Type: application/spkane.todo-list.v1+json" description="paint the house" completed:=false
```
(^ hmm, returns 502 gateway error...)

curl version:
```bash
$ curl -i http://todo-api.spkane.org:8080/ -X POST -H 'Content-Type: application/spkane.todo-list.v1+json' -d '{ "description":"paint the house", "completed":false }'
```


Published provider:
https://registry.terraform.io/providers/spkane/todo/1.2.3


Experimenting with this in the [todo-provider/terraform-tests](todo-provider/terraform-tests) dir. See comments for notes.



### Importing existing resources

```hcl
resource "todo" "imported" {
  description = "paint the house"
  completed = false
  id = 103 # was this included?
}
```

```bash
$ terraform import todo.imported[0]
```

This should link them together and add this todo to the state file.


### Renaming resources

There's a new directive around "move" where you can do this in the code.

Normally renaming a resource in TF code would do a destroy and re-create.

We need to manipulate the local state.

To rename above `imported` resource to `primary`:
```bash
$ terraform state move todo.imported todo.primary
```

_Might want to do this with load balancers or databases presumably, but feel like we should tend towards immutable infrastructure._


### Modules

TF code but reusable for DRY purposes.

Experimenting in [todo-provider/modules/todo-test-data](todo-provider/modules/todo-test-data). See comments for notes.


[Using](https://gist.github.com/spkane/df02f7858f6bef9f045fa1c296f8146f#utilize-the-module-1-of-2) the module.

In `main.tf`:
```hcl
module "series-data" {
    source       = "../modules/todo-test-data"
    number       = 5
    purpose      = "testing"
    team_name    = "oreilly"
    descriptions = ["my first completed todo", "my second completed todo",
                    "my third completed todo", "my fourth completed todo",
                    "my fifth completed todo"
                   ]
```

In `outputs.tf`:
```hcl
output "first_series_ids" {
  value = module.series-data.first_series_ids
}

output "second_series_ids" {
  value = module.series-data.second_series_ids
}
```

Have to run `tf init` again, which will initialize the module:
```bash
$ tf init
Initializing modules...
- series-data in ../modules/todo-test-data

...
```

