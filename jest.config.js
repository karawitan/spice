module.exports = {
  testEnvironment: 'node',
  setupFilesAfterEnv: ['./jest.setup.js'],
  testMatch: ['**/src/**/*.test.js'],
  collectCoverage: true,
  coverageDirectory: 'coverage',
  verbose: true,
};