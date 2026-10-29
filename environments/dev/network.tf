# Calling a module: `source` points at the module folder, and every other
# argument fills in one of its variables. Outputs are read as module.<name>.<output>.

module "network" {
  source = "../../modules/vpc"

  name                = "${var.project}-vpc"
  public_subnet_count = 2
}
