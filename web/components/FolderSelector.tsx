'use client'

import { useState } from 'react'
import type { Folder } from '@/types/index'
import FolderBottomSheet from './FolderBottomSheet'

interface FolderSelectorProps {
  folders: Folder[]
  selectedFolderId: string | null
  onSelect: (folderId: string) => void
}

export default function FolderSelector({
  folders,
  selectedFolderId,
  onSelect,
}: FolderSelectorProps) {
  const [showSheet, setShowSheet] = useState(false)

  const selectedFolder = folders.find((f) => f.folderId === selectedFolderId)
  const displayName = selectedFolder?.name || 'Select folder'

  return (
    <>
      <div className="sticky top-0 z-10 bg-background">
        <button
          onClick={() => setShowSheet(true)}
          className="w-full min-h-[44px] px-4 py-3 text-left bg-gray-50 hover:bg-gray-100 border-b border-gray-200 font-medium"
        >
          {displayName}
        </button>
      </div>

      {showSheet && (
        <FolderBottomSheet
          folders={folders}
          selectedFolderId={selectedFolderId}
          onSelect={onSelect}
          onClose={() => setShowSheet(false)}
        />
      )}
    </>
  )
}
