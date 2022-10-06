output "todo_1_ids" {
  value = todo.test1.*.id
  # note the *. to iterate over the array of IDs, since these were created with count
}

output "todo_2_ids" {
  value = todo.test2.*.id
}

# the type of these output vars is "list"


# note in main.tf data resources are referenced like this:
# ${data.todo.foreign.description}

# however, above we don't specify it as "resource.todo.test1...."
# "resource" is the default


# tf apply output:
#
# Outputs:
#
# todo_1_ids = [
#   "58",
#   "57",
#   "61",
#   "53",
#   "55",
# ]
# todo_2_ids = [
#   "59",
#   "62",
#   "56",
#   "54",
#   "60",
# ]



### using the module ###

output "first_series_ids" {
  value = module.series-data.first_series_ids
}

output "second_series_ids" {
  value = module.series-data.second_series_ids
}
