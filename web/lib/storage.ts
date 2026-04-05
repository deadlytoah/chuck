export function getStoredFolderId(): string | null {
  try {
    return localStorage.getItem('chuck.folderId')
  } catch {
    return null
  }
}

export function setStoredFolderId(id: string): void {
  try {
    localStorage.setItem('chuck.folderId', id)
  } catch {
    // Silently fail if localStorage is unavailable
  }
}
