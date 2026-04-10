import { test, expect } from '@playwright/test'
import { mockFolders, mockItems } from '../helpers/routes'
import { folders, itemsPage1 } from '../fixtures/data'

test('folder fetch error shows error banner', async ({ page }) => {
  await mockFolders(page, folders, 500)
  await mockItems(page, itemsPage1)

  await page.goto('/')

  // Assert error banner visible
  const errorBanner = page.locator('div.bg-yellow-100')
  await expect(errorBanner).toBeVisible()
})

test('retry success after error', async ({ page }) => {
  await mockFolders(page, folders)
  await mockItems(page, itemsPage1, { status: 500 })

  await page.goto('/')

  // Assert error banner visible
  const errorBanner = page.locator('div.bg-yellow-100')
  await expect(errorBanner).toBeVisible()

  // Re-mock items to 200
  await mockItems(page, itemsPage1)

  // Click retry button
  await page.locator('button:has-text("Retry")').click()

  // Assert error banner disappears and items load
  await expect(errorBanner).not.toBeVisible()
  const undecidedBadges = page.locator('span:has-text("Undecided")')
  await expect(undecidedBadges).toHaveCount(2)
})
