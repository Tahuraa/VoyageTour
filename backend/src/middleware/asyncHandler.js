// Wraps an async route handler so a rejected promise reaches Express's
// error middleware (a JSON 500) instead of becoming an unhandled rejection
// that crashes the whole server.
const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

module.exports = asyncHandler;
