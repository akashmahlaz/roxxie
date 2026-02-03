### 0 issue method keep in mind for flutter app files 
- Curly braces on ALL if/for/while: `if (x) { ... }`
- Null safety: `artist.displayName ?? 'Unknown'`
- Cache context before async: `final nav = Navigator.of(context);`
- Use `AppColors.crimson`, not `Colors.red`
- Single underscore: `(_, _, _)` not `(_, __, ___)`
- Enum comparison: `userRole == UserRole.artist`
- Dont use deprecated APIs use latest and long support and from official flutter.dev not random publishers 
- backend in gigmatch folder if any time changes needed after changes run pnpm exec tsc --noemit
### Dont do
- `withOpacity()` → use `withValues(alpha: 0.5)`
- `WillPopScope` → use `PopScope`
- Direct nullable access without `??`
- Context after await without caching

## After batch of Changes
Run `flutter analyze` after each batch of changes - must be 0 errors 0 issues 0 warnings  