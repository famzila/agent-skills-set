# my-supapp

Angular 21 application with SSR, routing, and a full quality toolchain.

## Scripts

| Command | Description |
|---------|-------------|
| `npm start` | Start dev server |
| `npm run build` | Production build |
| `npm test` | Run unit tests (Vitest) |
| `npm run lint` | ESLint check |
| `npm run lint:styles` | Stylelint check |
| `npm run format` | Prettier check |

## Quality Tools

- **ESLint** -- Code quality with Angular, import organization, and RxJS plugins
- **Stylelint** -- CSS linting
- **Prettier** -- Code formatting (integrated with ESLint)
- **Husky** -- Git hooks (pre-commit lint-staged, commit-msg commitlint)
- **Commitlint** -- Conventional Commits enforcement

## Commit Format

```
type(scope): description

types: feat, fix, docs, style, refactor, perf, test, chore, ci, build
```

## License

TBD
