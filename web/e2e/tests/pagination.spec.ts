import { test, expect } from '@playwright/test'
import { mockFolders, mockItems } from '../helpers/routes'
import { folders, itemsPage1, itemsPage2 } from '../fixtures/data'

test('Load More appends items', async ({ page }) => {
  await mockFolders(page, folders)
  await mockItems(page, itemsPage1, { nextToken: 'tok1' })

  await page.goto('/')

  // Assert 2 items visible
  const undecidedBadges = page.locator('span:has-text("Undecided")')
  await expect(undecidedBadges).toHaveCount(2)

  // Re-mock items to return itemsPage2 (no nextToken)
  await mockItems(page, itemsPage2)

  // Click 'Load More' button
  await page.locator('button:has-text("Load More")').click()

  // Assert 3 items total (2 Undecided + 1 Keep)
  const allBadges = page.locator(
    'span:has-text("Undecided"), span:has-text("Keep")'
  )
  await expect(allBadges).toHaveCount(3)
})
