resource "random_string" "this" {
  length = 16
}

output "result" {
  value = random_string.this.result
}
