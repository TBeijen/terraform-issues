terraform {
  required_providers {
  }
}

locals {
  list_1 = ["foo", "bar"]
  list_2 = ["foo", "bar", "baz"]
}

resource "random_pet" "names_1" {
  for_each = toset(local.list_1)

  keepers = {
    name = each.key
  }
}

resource "random_pet" "names_2" {
  depends_on = [random_pet.names_1]

  for_each = toset(local.list_2)

  keepers = {
    original_id = random_pet.names_1[each.key].id
  }
}
