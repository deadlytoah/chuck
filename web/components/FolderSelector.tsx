'use client'

import { useState, useRef, useEffect } from 'react'
import type { Folder } from '@/types/index'

interface FolderSelectorProps {
  folders: Folder[]
  selectedFolderId: string | null
  onSelect: (folderId: string) => void
  onRefresh?: () => void
}

export default function FolderSelector({
  folders,
  selectedFolderId,
  onSelect,
  onRefresh,
}: FolderSelectorProps) {
  const [isOpen, setIsOpen] = useState(false)
  const containerRef = useRef<HTMLDivElement>(null)
  const triggerRef = useRef<HTMLButtonElement>(null)
  const listboxRef = useRef<HTMLUListElement>(null)

  const selectedFolder = folders.find((f) => f.folderId === selectedFolderId)
  const displayName = selectedFolder?.name || 'Select folder'

  // Click-away handler
  useEffect(() => {
    if (!isOpen) return

    const handler = (e: MouseEvent) => {
      if (!containerRef.current?.contains(e.target as Node)) {
        setIsOpen(false)
      }
    }

    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [isOpen])

  // Escape key handler
  useEffect(() => {
    if (!isOpen) return

    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setIsOpen(false)
        triggerRef.current?.focus()
      }
    }

    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [isOpen])

  // Focus on open
  useEffect(() => {
    if (isOpen) {
      listboxRef.current?.querySelector('button')?.focus()
    }
  }, [isOpen])

  const handleSelect = (folderId: string) => {
    onSelect(folderId)
    setIsOpen(false)
    triggerRef.current?.focus()
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLUListElement>) => {
    const buttons = Array.from(
      listboxRef.current?.querySelectorAll('button') || []
    )
    const activeIndex = buttons.indexOf(
      document.activeElement as HTMLButtonElement
    )

    if (e.key === 'ArrowDown') {
      e.preventDefault()
      const nextIndex = (activeIndex + 1) % buttons.length
      ;(buttons[nextIndex] as HTMLButtonElement)?.focus()
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      const prevIndex = activeIndex === 0 ? buttons.length - 1 : activeIndex - 1
      ;(buttons[prevIndex] as HTMLButtonElement)?.focus()
    } else if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      const focused = document.activeElement as HTMLButtonElement
      const folderId = focused?.getAttribute('data-folder-id')
      if (folderId) {
        handleSelect(folderId)
      }
    }
  }

  return (
    <div ref={containerRef} className="relative">
      <div className="flex border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
        <button
          ref={triggerRef}
          onClick={() => setIsOpen((prev) => !prev)}
          className="flex-1 min-h-[44px] px-4 py-3 text-left bg-gray-50 hover:bg-gray-100 dark:bg-gray-800 dark:hover:bg-gray-700 font-medium text-gray-900 dark:text-gray-100 flex items-center gap-2"
          aria-haspopup="listbox"
          aria-expanded={isOpen}
          aria-controls="folder-listbox"
          id="folder-selector-btn"
        >
          <span>{displayName}</span>
          <svg
            className={`w-5 h-5 transition-transform ${
              isOpen ? 'rotate-180' : ''
            }`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M5 9l7 7 7-7"
            />
          </svg>
        </button>

        {onRefresh && (
          <button
            onClick={(e) => {
              e.stopPropagation()
              onRefresh()
            }}
            className="min-h-[44px] px-3 flex items-center justify-center hover:bg-gray-100 dark:hover:bg-gray-700 border-l border-gray-200 dark:border-gray-700"
            aria-label="Refresh"
            type="button"
          >
            <svg
              className="w-5 h-5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
          </button>
        )}
      </div>

      {isOpen && (
        <ul
          ref={listboxRef}
          role="listbox"
          id="folder-listbox"
          aria-labelledby="folder-selector-btn"
          className="absolute top-full left-0 right-0 z-50 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-b-lg shadow-lg max-h-60 overflow-y-auto"
          onKeyDown={handleKeyDown}
        >
          {folders.map((folder) => (
            <li
              key={folder.folderId}
              role="option"
              aria-selected={selectedFolderId === folder.folderId}
            >
              <button
                onClick={() => handleSelect(folder.folderId)}
                className={`w-full text-left px-4 py-3 border-b border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700 ${
                  selectedFolderId === folder.folderId
                    ? 'bg-blue-50 dark:bg-blue-900 font-semibold text-blue-600 dark:text-blue-300'
                    : 'text-gray-900 dark:text-gray-100'
                }`}
                data-folder-id={folder.folderId}
              >
                {folder.name}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
