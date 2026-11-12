import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const repoUrl = 'https://github.com/jordantrizz/zshbop';

// The local search index must be built for the same route the docs live on,
// otherwise every result points at /docs/... and 404s on a '/' site.
const themes: Config['themes'] = [
  [
    '@easyops-cn/docusaurus-search-local',
    {
      hashed: true,
      language: ['en'],
      indexBlog: false,
      docsRouteBasePath: '/',
    },
  ],
];

const config: Config = {
  title: 'zshbop',
  tagline: 'A custom Zsh configuration for people who live in a terminal.',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: 'https://jordantrizz.github.io',
  baseUrl: '/zshbop/',
  trailingSlash: false,

  onBrokenLinks: 'throw',
  onBrokenAnchors: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
          editUrl: `${repoUrl}/edit/main/website/`,
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themes,

  themeConfig: {
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'zshbop',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docs',
          position: 'left',
          label: 'Documentation',
        },
        {
          href: repoUrl,
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Overview',
              to: '/',
            },
            {
              label: 'What zshbop is',
              to: '/getting-started/what-is-zshbop',
            },
            {
              label: 'Tab completion',
              to: '/guides/tab-completion',
            },
          ],
        },
        {
          title: 'Project',
          items: [
            {
              label: 'GitHub',
              href: repoUrl,
            },
            {
              label: 'Issues',
              href: `${repoUrl}/issues`,
            },
          ],
        },
      ],
      copyright: 'zshbop · built with Docusaurus',
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'powershell', 'yaml', 'json', 'ini', 'diff'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
