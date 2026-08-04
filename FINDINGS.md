English | [简体中文](FINDINGS.zh-CN.md)

# Findings

## What we observed

In the recorded NFSv3 `cached` run, B kept reading `before` from an open handle until the attribute timeout; closing and reopening after A closed gave `after!`. With `noac`, B saw `after!` immediately, alongside 13 additional `GETATTR` calls in that run. In the write-policy run, B could read an empty value while A still held an `async` or `fsync` file open; `fsync` or `sync` made data visible before close. NFSv4 returned fresh data in the recorded run, but no delegation counters were available.

## Backend decision

Shared mounts make ticket readers depend on cache and open/close rules. Tickets are written and fetched as complete objects, so the backend chose object PUT/GET. These local measurements do not prove a general NFSv4 delegation rule. See [backend ADR 0011 — Store e-tickets as objects](https://github.com/codexary/stubline-backend/blob/main/docs/adr/0011-store-etickets-as-objects.md).
