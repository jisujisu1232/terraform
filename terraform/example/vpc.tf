data "aws_availability_zones" "available" {}

resource "aws_vpc" "jisu_vpc" {
  cidr_block = "10.10.0.0/16"
  enable_dns_hostnames = true
  tags = "${
    merge(
      map(
        "Name", "${var.project_name}-vpc",
        "kubernetes.io/cluster/${var.cluster-name}", "shared",
      ),
      var.project_tags
    )
  }"
}

resource "aws_subnet" "jisu-tf-pub" {
  vpc_id = "${aws_vpc.jisu_vpc.id}"
  count=2
  cidr_block = "10.10.1${count.index}.0/24"
  availability_zone = "${var.region}${var.availability_zones[count.index]}"
  tags = "${
    merge(
      map(
        "Name", "${var.project_name}-pub-${var.availability_zones[count.index]}",
        "kubernetes.io/cluster/${var.cluster-name}", "shared",
      ),
      var.project_tags
    )
  }"
}

resource "aws_subnet" "jisu-tf-pri" {
  vpc_id = "${aws_vpc.jisu_vpc.id}"
  count=2
  cidr_block = "10.10.2${count.index}.0/24"
  availability_zone = "${var.region}${var.availability_zones[count.index]}"
  tags = "${
    merge(
      map(
        "Name", "${var.project_name}-pri-${var.availability_zones[count.index]}"
      ),
      var.project_tags
    )
  }"
}

resource "aws_subnet" "jisu-tf-data" {
  vpc_id = "${aws_vpc.jisu_vpc.id}"
  count=2
  cidr_block = "10.10.3${count.index}.0/24"
  availability_zone = "${var.region}${var.availability_zones[count.index]}"
  tags = "${
    merge(
      map(
        "Name", "${var.project_name}-data-${var.availability_zones[count.index]}"
      ),
      var.project_tags
    )
  }"
}

resource "aws_internet_gateway" "jisu-tf-igw" {
  vpc_id = "${aws_vpc.jisu_vpc.id}"
  tags = "${
    merge(
      map(
        "Name", "${var.project_name}-igw"
      ),
      var.project_tags
    )
  }"
}

resource "aws_eip" "jisu-tf-nat-a-eip" {
  vpc  = true
  tags = "${
    merge(
      map(
        "Name", "${var.project_name}-nat-${var.availability_zones[0]}-eip"
      ),
      var.project_tags
    )
  }"
}

resource "aws_nat_gateway" "jisu-tf-nat" {
  allocation_id = "${aws_eip.jisu-tf-nat-a-eip.id}"
  subnet_id     = "${aws_subnet.jisu-tf-pub[0].id}"
  tags = "${
    merge(
      map(
        "Name", "${var.project_name}-nat-${var.availability_zones[0]}"
      ),
      var.project_tags
    )
  }"
}

resource "aws_route_table" "jisu-tf-pub-rt" {
  vpc_id = "${aws_vpc.jisu_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.jisu-tf-igw.id}"
  }

  tags = "${
    merge(
      map(
        "Name", "${var.project_name}-pub-rt"
      ),
      var.project_tags
    )
  }"
}

resource "aws_route_table" "jisu-tf-pri-rt" {
  vpc_id = "${aws_vpc.jisu_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.jisu-tf-nat.id}"
  }

  tags = "${
    merge(
      map(
        "Name", "${var.project_name}-pri-rt"
      ),
      var.project_tags
    )
  }"
}

resource "aws_route_table" "jisu-tf-data-rt" {
  vpc_id = "${aws_vpc.jisu_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.jisu-tf-nat.id}"
  }

  tags = "${
    merge(
      map(
        "Name", "${var.project_name}-data-rt"
      ),
      var.project_tags
    )
  }"
}

resource "aws_route_table_association" "jisu-tf-pub-rt-association" {
  count = "${length(aws_subnet.jisu-tf-pub)}"
  subnet_id      = "${aws_subnet.jisu-tf-pub[count.index].id}"
  route_table_id = "${aws_route_table.jisu-tf-pub-rt.id}"
}

resource "aws_route_table_association" "jisu-tf-pri-rt-association" {
  count = "${length(aws_subnet.jisu-tf-pri)}"
  subnet_id      = "${aws_subnet.jisu-tf-pri[count.index].id}"
  route_table_id = "${aws_route_table.jisu-tf-pri-rt.id}"
}

resource "aws_route_table_association" "jisu-tf-data-rt-association" {
  count = "${length(aws_subnet.jisu-tf-data)}"
  subnet_id      = "${aws_subnet.jisu-tf-data[count.index].id}"
  route_table_id = "${aws_route_table.jisu-tf-pri-rt.id}"
}
