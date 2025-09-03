/*
 * Viewer setup - minimal ProseMirror plugin configuration for read-only viewing
 */

import {history} from "prosemirror-history"
import {dropCursor} from "prosemirror-dropcursor"
import {gapCursor} from "prosemirror-gapcursor"

/**
 * Create a minimal plugin setup for the read-only viewer
 * 
 * This is much simpler than the full editor setup, containing only:
 * - Basic history tracking (for potential undo/redo in selection)
 * - Drop cursor (disabled for read-only)
 * - Gap cursor for better navigation
 * 
 * Notable exclusions from editor setup:
 * - Input rules (no editing)
 * - Key maps (no editing shortcuts)
 * - Menu bar (no editing tools)
 * - Editing commands (no formatting)
 */
export function viewerSetup(options) {
    const plugins = [
        // Keep minimal history for potential selection state tracking
        history({
            depth: 10,
            newGroupDelay: 500
        }),
        
        // Keep gap cursor for better navigation in read-only mode
        gapCursor(),
        
        // Drop cursor disabled since we're read-only, but include for consistency
        dropCursor({ color: 'transparent' })
    ];

    return plugins;
}
