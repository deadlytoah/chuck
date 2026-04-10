import { test, expect } from '@playwright/test'
import { mockFolders, mockItems } from '../helpers/routes'
import { folders, itemsPage1, archiveItems } from '../fixtures/data'

test('switching folder replaces item list', async ({ page }) => {
  await mockFolders(page, folders)
  await mockItems(page, itemsPage1)

  await page.goto('/')

  // Wait for 2 items
  const undecidedBadges = page.locator('span:has-text("Undecided")')
  await expect(undecidedBadges).toHaveCount(2)

  // Re-mock items to return archiveItems
  await mockItems(page, archiveItems)

  // Click folder selector button to open dropdown
  await page.locator('#folder-selector-btn').click()

  // Click button[data-folder-id="f2"]
  await page.locator('button[data-folder-id="f2"]').click()

  // Assert 1 item with state 'Chuck'
  const chuckBadges = page.locator('span:has-text("Chuck")')
  await expect(chuckBadges).toHaveCount(1)
})
