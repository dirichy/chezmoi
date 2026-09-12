skRegisterScript({ name: "github-search", domains: "github.com" }, ({ script }) => {
  const editableSelector = [
    'input:not([type="hidden"]):not([disabled])',
    "textarea:not([disabled])",
    '[contenteditable="true"]',
    '[role="textbox"]',
  ].join(",");

  const quickSearchButtonSelector =
    'button[aria-label="Open quick search dialog, type / to search"]';

  const isVisible = (element) => {
    if (!(element instanceof HTMLElement)) {
      return false;
    }

    const rect = element.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0;
  };

  const visibleEditables = (root = document) =>
    Array.from(root.querySelectorAll(editableSelector)).filter(isVisible);

  const quickSearchButton = () => document.querySelector(quickSearchButtonSelector);

  const quickSearchButtonFromTarget = (element) => {
    if (!(element instanceof Element)) {
      return null;
    }

    return element.closest(quickSearchButtonSelector);
  };

  const inputTargets = () => {
    const targets = visibleEditables();
    const searchButton = quickSearchButton();

    if (searchButton) {
      targets.push(searchButton);
    }

    return Array.from(new Set(targets)).filter(isVisible);
  };

  const focusElement = (element) => {
    if (!(element instanceof HTMLElement)) {
      return false;
    }

    element.focus();
    if (typeof element.select === "function") {
      element.select();
    }
    return document.activeElement === element;
  };

  const githubSearchDialog = () => {
    const selectors = [
      '[role="dialog"]',
      '[aria-modal="true"]',
      ".Overlay",
      ".overlay",
    ];

    return selectors
      .flatMap((selector) => Array.from(document.querySelectorAll(selector)))
      .filter(isVisible)
      .at(-1);
  };

  const githubDialogSearchTarget = () => {
    const dialog = githubSearchDialog();
    if (!dialog) {
      return null;
    }

    const preferredSelectors = [
      "#query-builder-test",
      'input[name="query-builder-test"]',
      'input[aria-label*="Search"]',
      'textarea[aria-label*="Search"]',
      'input[placeholder*="Search"]',
      'input[type="search"]',
    ];

    for (const selector of preferredSelectors) {
      const target = dialog.querySelector(selector);
      if (isVisible(target)) {
        return target;
      }
    }

    return visibleEditables(dialog)[0] || null;
  };

  const focusSearchAfterDialogOpens = () => {
    let attempts = 0;
    const maxAttempts = 40;

    const timer = setInterval(() => {
      attempts += 1;
      const target = githubDialogSearchTarget();
      if (focusElement(target) || attempts >= maxAttempts) {
        clearInterval(timer);
      }
    }, 50);
  };

  const clickElement = (element) => {
    if (api.Hints.dispatchMouseClick) {
      api.Hints.dispatchMouseClick(element);
      return;
    }

    element.click();
  };

  const focusOrOpenTarget = (element) => {
    const searchButton = quickSearchButtonFromTarget(element);
    if (searchButton instanceof HTMLElement) {
      clickElement(searchButton);
      focusSearchAfterDialogOpens();
      return;
    }

    focusElement(element);
  };

  const hintInputTarget = () => {
    if (!api.Hints.create) {
      skWarn("Surfingkeys Hints API not available");
      return;
    }

    const targets = inputTargets();
    if (targets.length === 0) {
      skWarn("GitHub input target not found");
      return;
    }

    api.Hints.create(targets, focusOrOpenTarget);
  };

  api.mapkey("i", "#8Choose GitHub input target", hintInputTarget, {
    domain: script.urlPattern,
  });
});
