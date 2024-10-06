# Step 1: terraform apply
#
# Step 2: terraform apply -var trigger_bug=true 
#
# This will show key not being found, but does not give full info about the key that was not found, 
# item_name is not shown in the error message.
#
#│ Error: Invalid index
#│
#│   on main.tf line 73, in locals:
#│   73:         list1_id = random_pet.complex_names_1["key-${elm.name}-${item_name}"].id
#│     ├────────────────
#│     │ elm.name is "elm2"
#│     │ random_pet.complex_names_1 is object with 2 attributes
#│
#│ The given key does not identify an element in this collection value.

terraform {
  required_providers {
  }
}

variable "trigger_bug" {
  type    = bool
  default = false
}

locals {
  simple_1 = ["foo", "bar"]
  simple_2 = concat(
    ["foo", "bar"],
    var.trigger_bug ? ["baz"] : [],
  )

  # Source lists. Nested data structures fed into the Terraform project.
  source_list_1 = [
    {
      name  = "elm1",
      items = ["foo"]
    },
    {
      name  = "elm2",
      items = ["bar"]
    },
  ]
  source_list_2 = [
    {
      name = "elm1",
      items = {
        foo = "123547asd"
      }
    },
    {
      name = "elm2",
      items = merge(
        {
          bar = "asdq34324"
        },
        var.trigger_bug ? {
          baz = "ljkfgh89"
        } : {}
      )
    },
  ]

  # Flattened source list 1:
  # - To easily iterate over when creating resources
  # - Defines the key for each element in the resources collection
  flat_1 = flatten([
    for elm in local.source_list_1 : [
      for item in elm.items : {
        name = elm.name
        item = item
        key  = "key-${elm.name}-${item}"
      }
    ]
  ])

  # Flattened source list 1:
  # - Similar to list 1
  # - Looks up the id of the corresponding element in list 1, thereby creating a dependency that Terraform will resolve
  #
  # >>> If lookup fails, not all the strings used in the lookup key will de shown in the error message
  flat_2 = flatten([
    for elm in local.source_list_2 : [
      for item_name, item_value in elm.items : {
        name     = elm.name
        item     = item_name
        value    = item_value
        list1_id = random_pet.complex_names_1["key-${elm.name}-${item_name}"].id
        key      = "key-${elm.name}-${item_name}"
      }
    ]
  ])
}

# Resources based on simple lists
resource "random_pet" "simple_names_1" {
  for_each = toset(local.simple_1)
  keepers = {
    name = each.key
  }
}

resource "random_pet" "simple_names_2" {
  for_each = toset(local.simple_2)
  keepers = {
    original_id = random_pet.simple_names_1["${each.key}"].id
  }
}

# Resources based on complex lists, with lookups
resource "random_pet" "complex_names_1" {
  for_each = {
    for item in local.flat_1 : item.key => item
  }
  keepers = {
    name = each.value.name
    item = each.value.item
  }
}

resource "random_pet" "complex_names_2" {
  for_each = {
    for item in local.flat_2 : item.key => item
  }
  keepers = {
    id = each.value.list1_id
  }
}
