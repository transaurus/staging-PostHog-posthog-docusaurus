// @ts-check
/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'PostHog Docusaurus Plugin',
  tagline: 'PostHog analytics plugin for Docusaurus',
  url: 'https://posthog.com',
  baseUrl: '/',
  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',
  i18n: {
    defaultLocale: 'en',
    locales: ["en", "zh-Hans"],
  },
  presets: [
    [
      'classic',
      {
        docs: false,
        blog: false,
        theme: {},
      },
    ],
  ],
};

module.exports = config;
