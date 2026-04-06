'use client'

import { useEffect, useRef } from 'react'
import type { Folder } from '@/types/index'

interface FolderBottomSheetProps {
  folders: Folder[]
  selectedFolderId: string | null
  onSelect: (folderId: string) => void
  onClose: () => void
}

export default function FolderBottomSheet({
  folders,
  selectedFolderId,
  onSelect,
  onClose,
}: FolderBottomSheetProps) {
  const sheetRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    // Use rAF so browser paints initial translateY(100%) before animating
    const id = requestAnimationFrame(() => {
      sheetRef.current?.classList.add('open')
    })
    return () => cancelAnimationFrame(id)
  }, [])

  const handleBackdropClick = () => {
    onClose()
  }

  const handleFolderSelect = (folderId: string) => {
    onSelect(folderId)
    onClose()
  }

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 z-40"
      onClick={handleBackdropClick}
    >
      <div
        ref={sheetRef}
        className="bottom-sheet fixed bottom-0 left-0 right-0 bg-white rounded-t-lg shadow-lg z-50 max-h-[80vh] flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex justify-between items-center p-4 border-b">
          <h2 className="text-lg font-semibold">Select Folder</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700"
            aria-label="Close"
          >
            <svg
              className="w-6 h-6"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <div className="overflow-y-auto flex-1">
          {folders.map((folder) => (
            <button
              key={folder.folderId}
              onClick={() => handleFolderSelect(folder.folderId)}
              className={`w-full text-left px-4 py-3 border-b hover:bg-gray-50 ${
                selectedFolderId === folder.folderId
                  ? 'bg-blue-50 font-semibold text-blue-600'
                  : ''
              }`}
            >
              {folder.name}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}
