import type { Page } from '@playwright/test'
import type { Folder, Item } from '../../types/index'

export async function mockFolders(page: Page, folders: Folder[], status = 200) {
  await page.route('**/folders', async (route) => {
    if (status !== 200) {
      await route.fulfill({ status, body: 'Error' })
    } else {
      await route.fulfill({ json: { data: folders } })
    }
  })
}

export async function mockItems(
  page: Page,
  items: Item[],
  opts: { nextToken?: string; status?: number } = {}
) {
  await page.route('**/items?**', async (route) => {
    if (opts.status && opts.status !== 200) {
      await route.fulfill({ status: opts.status, body: 'Error' })
    } else {
      await route.fulfill({
        json: {
          data: items,
          pagination: opts.nextToken
            ? { nextToken: opts.nextToken }
            : undefined,
          meta: { count: items.length },
        },
      })
    }
  })
}

export async function mockUpdateItem(
  page: Page,
  responseItem: Item,
  status = 200
) {
  await page.route('**/items/**', async (route) => {
    if (route.request().method() !== 'PUT') {
      await route.continue()
      return
    }
    if (status !== 200) {
      await route.fulfill({ status, body: 'Error' })
    } else {
      await route.fulfill({ json: responseItem })
    }
  })
}
