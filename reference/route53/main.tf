# Route 53 = AWS's DNS service: turns names (app.example.com) into addresses.
#   hosted zone -> all records for one domain; public (internet) or private (inside VPCs)
#   record      -> name + type (A, AAAA, CNAME, MX, TXT, ...) + value + TTL
#   alias       -> Route 53's special record pointing at AWS resources (ALB,
#                  CloudFront, S3 website); free to query and works at the zone apex
#   routing     -> simple, weighted, latency, failover, geolocation
#
# Registering the domain itself is separate (Route 53 Domains or any registrar);
# you then point the domain's name servers at this zone's NS records.

resource "aws_route53_zone" "main" {
  name    = "example-shop.com"
  comment = "Public zone for the demo shop"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example-shop.com"
  type    = "A"
  ttl     = 300 # seconds resolvers may cache the answer
  records = ["203.0.113.10"]
}

resource "aws_route53_record" "blog" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "blog"  # relative names are completed with the zone name
  type    = "CNAME" # an alias for another name; not allowed at the zone apex
  ttl     = 300
  records = ["www.example-shop.com"]
}

resource "aws_route53_record" "spf" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example-shop.com"
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com ~all"]
}

# Weighted routing: send 90% of lookups to v1 and 10% to v2 (canary release).
resource "aws_route53_record" "api" {
  for_each = { v1 = { ip = "203.0.113.20", weight = 90 }, v2 = { ip = "203.0.113.21", weight = 10 } }

  zone_id        = aws_route53_zone.main.zone_id
  name           = "api.example-shop.com"
  type           = "A"
  ttl            = 60
  records        = [each.value.ip]
  set_identifier = each.key # required to tell records with the same name apart

  weighted_routing_policy {
    weight = each.value.weight
  }
}

# Alias at the apex to a load balancer (needs ../alb):
# resource "aws_route53_record" "apex" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "example-shop.com"
#   type    = "A"
#   alias {
#     name                   = aws_lb.web.dns_name
#     zone_id                = aws_lb.web.zone_id
#     evaluate_target_health = true
#   }
# }
