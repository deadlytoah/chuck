import { test, expect } from '@playwright/test'
import { mockFolders, mockItems } from '../helpers/routes'
import { folders, itemsPage1 } from '../fixtures/data'

test('auto-selects Inbox, shows its items', async ({ page }) => {
  await mockFolders(page, folders)
  await mockItems(page, itemsPage1)

  await page.goto('/')

  // Assert FolderSelector shows 'Inbox'
  await expect(page.locator('#folder-selector-btn')).toContainText('Inbox')

  // Assert 2 item state badges visible (text 'Undecided')
  const undecidedBadges = page.locator('span:has-text("Undecided")')
  await expect(undecidedBadges).toHaveCount(2)
})
