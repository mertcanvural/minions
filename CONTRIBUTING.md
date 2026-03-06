# Contributing to Minions

Thanks for your interest in contributing. This project is inspired by Stripe's approach to agentic engineering — we welcome contributions that align with the core design principles.

## Getting Started

1. Fork the repo and clone locally
2. Create a feature branch from `main`
3. Make your changes
4. Run the MissionControl app to verify: `cd MissionControl && swift build`
5. Open a pull request against `main`

## Project Structure

```
minions/
  docs/              # Architecture and design documentation
  MissionControl/    # macOS SwiftUI companion app
    Sources/         # App source code
    Tests/           # Unit and UI tests
  README.md
```

## Guidelines

- **Keep it simple** — follow the principle of interleaving determinism with agents
- **One concern per PR** — atomic, focused changes are easier to review
- **Read the docs first** — the `docs/` folder covers architecture, blueprint engine, agent routing, and more
- **Swift conventions** — use `@Observable`, Apple frameworks only, support dark/light mode
- **No external dependencies** for MissionControl — everything uses native Apple frameworks

## Areas for Contribution

- New agent profiles and routing strategies
- Blueprint engine node types
- MissionControl UI improvements
- Documentation and examples
- Tool Shed integrations

## Reporting Issues

Open an issue with:
- What you expected
- What happened instead
- Steps to reproduce

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
