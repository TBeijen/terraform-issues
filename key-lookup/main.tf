terraform {
  required_providers {
  }
}

locals {
  simple_1 = ["foo", "bar"]
  simple_2 = ["foo", "bar"]
  #   simple_2 = ["foo", "bar", "baz"]

  my_data = [
    {
      name = "elm1",
      items = {
        foo = "34sdf"
      }
    },
    {
      name = "elm2",
      items = {
        bar = "34sdf"
      }
    },

  ]
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
      name  = "elm1",
      items = ["foo"]
      items_alt = {
        foo = "123547asd"
      }
    },
    {
      name  = "elm2",
      items = ["bar", "baz"]
      items_alt = {
        bar = "asdq34324"
        baz = "ljkfgh89"
      }
    },
  ]

  # Flattened source lists, to easily iterate over them and create resources
  flat_1 = flatten([
    for elm in local.source_list_1 : [
      for item in elm.items : {
        name = elm.name
        item = item
        key  = "key-${elm.name}-${item}"
      }
    ]
  ])

  flat_2 = flatten([
    for foo in ["one_item"] : [
      for elm in local.source_list_2 : [
        for item_name, item_value in elm.items_alt : {
          foo      = foo
          name     = elm.name
          item     = item_name
          value    = item_value
          list1_id = random_pet.complex_names_1["key-${elm.name}-${item_name}"].id
          key      = "key-${elm.name}-${item_name}"
        }
      ]
    ]
  ])

  # We need predicatable lookup keys
  keyed_1 = {
    for item in local.flat_1 : item.key => item
  }

  keyed_2 = {
    for item in local.flat_2 : item.key => item
  }

  #   # Data structure to lookup the realms by name
  #   # Data structure to lookup the pets by name
  #   LOOKUP_pets_1 = {

  #   }
  #     LOOKUP_realms = merge(
  #     { for realm_name in try(local.current_slice_data.realms, []) : realm_name => module.realms[realm_name].realm },
  #     { for realm_name in try(local.current_slice_data.realms_ro, []) : realm_name => data.keycloak_realm.realms[realm_name] }
  #   )

}

resource "random_pet" "simple_names_1" {
  for_each = toset(local.simple_1)

  keepers = {
    name = each.key
  }
}

resource "random_pet" "simple_names_2" {
  depends_on = [random_pet.simple_names_1]

  for_each = toset(local.simple_2)

  keepers = {
    original_id = random_pet.simple_names_1["${each.key}"].id
  }
}

resource "random_pet" "complex_names_1" {
  for_each = local.keyed_1

  keepers = {
    name = each.value.name
    item = each.value.item
  }
}

resource "random_pet" "complex_names_2" {
  for_each = local.keyed_2

  keepers = {
    id = random_pet.complex_names_1[each.key].id
  }
}


output "flat_1" {
  value = local.flat_1
}

output "flat_2" {
  value = local.flat_2
}
output "keyed_1" {
  value = local.keyed_1
}
