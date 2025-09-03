import {EditorState} from "prosemirror-state"
import {EditorView} from "prosemirror-view"
import {Schema, DOMParser} from "prosemirror-model"
import {schema} from "../js/schema/index.js"
import {viewerSetup} from "./setup/index.js"

import {
  setHTML,
  getHeight,
  setMessageHandler,
  loadUserFiles,
  getSelectionText,
  selectAll,
  stateChanged,
  resetSelection,
} from "./markupViewer.js"

/**
 * The public MarkupViewer API callable from Swift as "MV.<function name>"
 */
export {
  setHTML,
  getHeight,
  setMessageHandler,
  loadUserFiles,
  getSelectionText,
  selectAll,
}

const mvSchema = new Schema({
  nodes: schema.spec.nodes,
  marks: schema.spec.marks
})

// Disable context menu to allow custom selection handling
document.addEventListener('contextmenu', e => e.preventDefault());

// Global state for height tracking and Swift communication
let documentHeight = 0;

window.view = new EditorView(document.querySelector("#editor"), {
  state: EditorState.create({
    doc: DOMParser.fromSchema(mvSchema).parse(document.querySelector("#editor")),
    plugins: viewerSetup({
      schema: mvSchema
    })
  }),
  // Make the editor read-only
  editable: () => false,
  // Handle selection changes for custom menu
  handleDOMEvents: {
    selectionchange(view, event) {
      const selection = view.state.selection;
      if (!selection.empty) {
        // Notify Swift that text is selected
        stateChanged({
          messageType: 'textSelected',
          hasSelection: true,
          selectedText: getSelectionText()
        });
      } else {
        // Notify Swift that selection is cleared
        stateChanged({
          messageType: 'selectionCleared',
          hasSelection: false
        });
      }
      return false;
    }
  }
})

// Watch for content height changes and notify Swift
function updateHeight() {
  const newHeight = getHeight();
  if (newHeight !== documentHeight) {
    documentHeight = newHeight;
    stateChanged({
      messageType: 'heightChanged',
      height: newHeight
    });
  }
}

// Set up observer for height changes
const resizeObserver = new ResizeObserver(() => {
  updateHeight();
});

// Observe the editor element for size changes
resizeObserver.observe(document.querySelector("#editor"));

// Also check height on initial load and content changes
window.addEventListener('load', updateHeight);
