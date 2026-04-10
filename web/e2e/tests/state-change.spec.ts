import { test, expect } from '@playwright/test'
import { mockFolders, mockItems, mockUpdateItem } from '../helpers/routes'
import { folders, itemsPage1 } from '../fixtures/data'

test('success: change state from Undecided to Keep', async ({ page }) => {
  await mockFolders(page, folders)
  await mockItems(page, itemsPage1)

  const updatedItem = {
    ...itemsPage1[0],
    state: 'Keep',
    updatedAt: new Date().toISOString(),
  }
  await mockUpdateItem(page, updatedItem)

  await page.goto('/')

  // Click item card image
  const itemCard = page.locator('.aspect-square').first()
  await itemCard.click()

  // Assert StateOverlay appears - look for state buttons
  const overlay = page.locator('.overlay-open')
  await expect(overlay).toBeVisible()

  // Click 'Keep' button inside the overlay
  await overlay.locator('button:has-text("Keep")').click()

  // Assert badge shows 'Keep'
  const keepBadge = page.locator('span:has-text("Keep")')
  await expect(keepBadge).toBeVisible()
})

test('rollback: revert state on PUT 500 error', async ({ page }) => {
  await mockFolders(page, folders)
  await mockItems(page, itemsPage1)
  await mockUpdateItem(page, itemsPage1[0], 500)

  await page.goto('/')

  // Click item card image
  const itemCard = page.locator('.aspect-square').first()
  await itemCard.click()

  // Click 'Keep' button
  const overlay = page.locator('.overlay-open')
  await overlay.locator('button:has-text("Keep")').click()

  // Assert badge reverts to 'Undecided'
  const undecidedBadges = page.locator('span:has-text("Undecided")')
  await expect(undecidedBadges).toHaveCount(2)

  // Assert error banner visible
  const errorBanner = page.locator('div.bg-yellow-100')
  await expect(errorBanner).toBeVisible()
})
