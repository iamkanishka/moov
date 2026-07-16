# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - Unreleased

### Added

- Initial release covering the full Moov API reference:
  - **Moov accounts**: `Moov.Accounts`, `Moov.Billing`, `Moov.Capabilities`,
    `Moov.Files`, `Moov.OnboardingLinks`, `Moov.ResolutionLinks`,
    `Moov.PartnerBilling`, `Moov.Representatives`, `Moov.Underwriting`
  - **Sources**: `Moov.BankAccounts`, `Moov.Cards`, `Moov.ApplePay`,
    `Moov.GooglePay`, `Moov.PaymentMethods`, `Moov.TerminalApplications`,
    `Moov.Wallets`
  - **Money movement**: `Moov.Transfers`, `Moov.Sweeps`, `Moov.Refunds`,
    `Moov.Disputes`, `Moov.CardIssuing`, `Moov.Invoices`,
    `Moov.PaymentLinks`, `Moov.Receipts`, `Moov.Schedules`
  - **Account tools**: `Moov.Images`, `Moov.Products`, `Moov.SupportTickets`
  - **Enrichment**: `Moov.Branding`, `Moov.Enrichment`, `Moov.Institutions`
  - **Authentication**: `Moov.AccessTokens`, `Moov.E2EE`
- Core engine: `Moov.Client` (Req-based, Basic/Bearer auth,
  `X-Moov-Version` handling), `Moov.Error` (structured, raisable errors),
  `Moov.Retry` (exponential backoff with full jitter for transient
  failures), `Moov.Telemetry` (`:telemetry` events for every request and
  retry), `Moov.Webhook` (HMAC-SHA512 signature verification + event
  parsing), `Moov.CaseConverter` (snake_case/camelCase translation at the
  request/response boundary), `Moov.UUID` (dependency-free idempotency key
  generation).
- Automatic, reused-across-retries idempotency key support on
  `Moov.Transfers.create/4` and any other write call via `idempotent: true`.
- Multipart file upload support (`Moov.Files`, `Moov.Images`,
  `Moov.Disputes.upload_evidence_file/5`).
