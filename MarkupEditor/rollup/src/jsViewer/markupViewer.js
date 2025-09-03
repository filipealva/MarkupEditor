/*
 MarkupViewer.js - Read-only version of MarkupEditor
 
 Edit only from within MarkupEditor/rollup/src/jsViewer. After running "npm run build:viewer",
 the rollup output is copied into MarkupEditor/Resources/markupViewer.js.
 */

import {DOMParser, DOMSerializer} from 'prosemirror-model'
import {AllSelection} from 'prosemirror-state'

// Global variables
let messageHandler = null;

/**
 * Set the message handler for Swift communication
 */
export function setMessageHandler(handler) {
    messageHandler = handler;
}

/**
 * Send a message to Swift side
 */
function _callback(message) {
    if (messageHandler) {
        messageHandler(message);
    } else if (window.webkit?.messageHandlers?.markup) {
        window.webkit.messageHandlers.markup.postMessage(message);
    }
}

/**
 * Notify Swift of state changes
 */
export function stateChanged(data = {}) {
    _callback(JSON.stringify({
        messageType: 'stateChanged',
        ...data
    }));
}

/**
 * Set HTML content in the viewer (read-only)
 */
export function setHTML(html, focusAfterLoad = false) {
    if (!window.view) return;
    
    try {
        // Create a temporary div to parse the HTML
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = html || '';
        
        // Parse the HTML into ProseMirror document
        const doc = DOMParser.fromSchema(window.view.state.schema).parse(tempDiv);
        
        // Create new state with the parsed document
        const newState = window.view.state.reconfigure({
            doc: doc
        });
        
        // Update the view
        window.view.updateState(newState);
        
        // Reset selection to avoid any focus issues
        resetSelection();
        
        stateChanged({
            messageType: 'htmlLoaded'
        });
        
    } catch (error) {
        console.error('Error setting HTML:', error);
        stateChanged({
            messageType: 'error',
            error: error.message
        });
    }
}

/**
 * Get the current document height
 */
export function getHeight() {
    if (!window.view) return 0;
    
    const editor = document.querySelector('#editor');
    if (!editor) return 0;
    
    // Get the actual content height including all elements
    const height = Math.max(
        editor.scrollHeight,
        editor.offsetHeight,
        editor.getBoundingClientRect().height
    );
    
    return Math.ceil(height);
}

/**
 * Get the currently selected text
 */
export function getSelectionText() {
    if (!window.view) return '';
    
    const { state } = window.view;
    const { selection } = state;
    
    if (selection.empty) return '';
    
    return state.doc.textBetween(selection.from, selection.to, ' ');
}

/**
 * Select all text in the document
 */
export function selectAll() {
    if (!window.view) return;
    
    const { state, dispatch } = window.view;
    const allSelection = new AllSelection(state.doc);
    const tr = state.tr.setSelection(allSelection);
    
    dispatch(tr);
    
    stateChanged({
        messageType: 'textSelected',
        hasSelection: true,
        selectedText: getSelectionText()
    });
}

/**
 * Clear the current selection
 */
export function resetSelection() {
    if (!window.view) return;
    
    const { state, dispatch } = window.view;
    const tr = state.tr.setSelection(state.selection.constructor.atStart(state.doc));
    
    dispatch(tr);
    
    stateChanged({
        messageType: 'selectionCleared',
        hasSelection: false
    });
}

/**
 * Load user CSS and JS files (placeholder for compatibility)
 */
export function loadUserFiles(scriptFile, cssFile) {
    // Load CSS file if specified
    if (cssFile && cssFile !== 'null') {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = cssFile;
        document.head.appendChild(link);
    }
    
    // Load JS file if specified  
    if (scriptFile && scriptFile !== 'null') {
        const script = document.createElement('script');
        script.src = scriptFile;
        document.head.appendChild(script);
    }
    
    // Notify Swift that user files are loaded
    stateChanged({
        messageType: 'userFilesLoaded'
    });
}

/**
 * Copy selected text to clipboard (called from Swift)
 */
export function copySelection() {
    const selectedText = getSelectionText();
    if (selectedText) {
        if (navigator.clipboard) {
            navigator.clipboard.writeText(selectedText).then(() => {
                stateChanged({
                    messageType: 'textCopied',
                    text: selectedText
                });
            }).catch(err => {
                console.error('Failed to copy text:', err);
            });
        }
    }
}
