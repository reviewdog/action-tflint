resource "azurerm_virtual_machine" "foo" {
  vm_size = "Standard_DS1_v3" # invalid type!
}
