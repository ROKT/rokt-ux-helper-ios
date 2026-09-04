# Public content checklist

**This is a public repository. Never publish Rokt-internal information, secrets, or personally identifiable information (PII).** Draft PRs and review discussions are public too. These rules apply to agents and human contributors, including follow-up comments after the initial PR review.

## What must stay out

- Non-public Rokt business information, plans, launch dates, incidents, partner requirements, internal discussions, and implementation or infrastructure details.
- Private repository, issue, PR, document, chat, dashboard, or service links; internal hostnames and account, tenant, campaign, or other business identifiers.
- Real customer, partner, advertiser, or employee personal information, including names, email addresses, phone numbers, addresses, IP addresses, device identifiers, and combinations that identify a person. Hashing or partially masking a value does not automatically make it safe.
- Credentials and authentication material: tokens, cookies, keys, passwords, authorization headers, connection strings, signed URLs, and secrets embedded in payloads or images.
- Unreviewed production responses, logs, crash reports, screenshots, recordings, result bundles, and attachments. Their metadata, filenames, local paths, browser chrome, or background windows can also disclose private information.

Public SDK names, public APIs, and already-public documentation can be referenced when relevant. Explain behavior at the public client boundary; do not add the private context that motivated a change. Use deliberately synthetic fixtures and reserved example domains. Do not copy real values and assume changing a few fields anonymizes them.

## Before every public write

1. Inspect the exact branch name, commits and diff being pushed, or the exact title, body, comment, review reply and attachments being submitted. Do not rely on an earlier review of a different draft.
2. Remove private rationale and links. Replace real payloads with a minimal synthetic reproduction. For a public issue reference, verify that the issue itself is public; otherwise omit it.
3. Open every image or recording and review any text and metadata. Review logs and test reports before attaching them; a generated artifact is not automatically safe to publish.
4. Run the repository's configured secret checks for code changes. Also review manually for internal information and PII: secret scanners cannot enforce this whole policy.
5. State validation accurately using safe summaries. Do not paste raw terminal output or private investigation notes into a PR or review reply.
6. If uncertain, stop that publication, omit the uncertain content, and request a safe description through an approved private channel. Do not post it temporarily for someone else to sanitize.

The PR template checklist applies to the initial submission. Repeat this review for every subsequent commit, comment, review reply, and attachment; checking the box once does not approve future content.

## If a disclosure is discovered

Stop further publication and report it through the approved private process. For a security concern, follow [SECURITY.md](../SECURITY.md); do not open a public issue containing the exposed material. Removing the latest text or commit is not evidence that copies, notifications, artifacts, or history have been erased. Do not repeat the sensitive value while reporting the incident.
