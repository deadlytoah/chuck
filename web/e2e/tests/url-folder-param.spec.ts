import { test, expect } from '@playwright/test'
import { mockFolders, mockItems } from '../helpers/routes'
import { folders, itemsPage1, archiveItems } from '../fixtures/data'

test('navigating to /?folder=f2 selects Archive folder', async ({ page }) => {
  await mockFolders(page, folders)
  await mockItems(page, archiveItems)

  await page.goto('/?folder=f2')

  await expect(page.locator('#folder-selector-btn')).toContainText('Archive')

  const chuckBadges = page.locator('span:has-text("Chuck")')
  await expect(chuckBadges).toHaveCount(1)
})

test('initial load without query string sets URL to /?folder={folderId}', async ({
  page,
}) => {
  await mockFolders(page, folders)
  await mockItems(page, itemsPage1)

  await page.goto('/')

  // Wait for URL to be updated by router.replace
  await expect(page).toHaveURL(/folder=f1/)
})

test('invalid folder param shows toast and falls back to default', async ({
  page,
}) => {
  await mockFolders(page, folders)
  await mockItems(page, itemsPage1)

  await page.goto('/?folder=nonexistent')

  // Toast should appear
  const toast = page.locator('div.fixed.bottom-4')
  await expect(toast).toBeVisible()
  await expect(toast).toContainText('Folder not found')

  // Falls back to default (Inbox)
  await expect(page.locator('#folder-selector-btn')).toContainText('Inbox')
})
