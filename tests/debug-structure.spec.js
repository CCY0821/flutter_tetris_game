// @ts-check
const { test, expect } = require('@playwright/test');

test('Debug Flutter app structure', async ({ page }) => {
  await page.goto('http://localhost:8080');
  
  // Wait for page to load
  await page.waitForTimeout(5000);
  
  // Get all elements and their structure
  const bodyContent = await page.evaluate(() => {
    const getAllSelectors = (element, depth = 0) => {
      const result = [];
      const indent = '  '.repeat(depth);
      
      const tagName = element.tagName.toLowerCase();
      const id = element.id ? `#${element.id}` : '';
      const classes = element.className ? `.${element.className.split(' ').join('.')}` : '';
      const selector = `${tagName}${id}${classes}`;
      
      result.push(`${indent}${selector}`);
      
      if (depth < 3) { // Limit depth to avoid too much output
        Array.from(element.children).forEach(child => {
          result.push(...getAllSelectors(child, depth + 1));
        });
      }
      
      return result;
    };
    
    return getAllSelectors(document.body).join('\n');
  });
  
  console.log('Page structure:');
  console.log(bodyContent);
  
  // Take a screenshot
  await page.screenshot({ path: 'debug-screenshot.png', fullPage: true });
  
  // Check what Flutter actually creates
  const flutterElements = await page.evaluate(() => {
    const elements = [];
    
    // Common Flutter web selectors
    const selectors = [
      'flutter-view',
      'flt-glass-pane',
      'flt-canvas',
      'flt-scene-host',
      '[flt-renderer]',
      'canvas',
      'div[style*="position: absolute"]'
    ];
    
    selectors.forEach(selector => {
      const element = document.querySelector(selector);
      if (element) {
        elements.push({
          selector,
          found: true,
          tagName: element.tagName,
          className: element.className,
          id: element.id
        });
      } else {
        elements.push({ selector, found: false });
      }
    });
    
    return elements;
  });
  
  console.log('Flutter elements check:');
  console.log(JSON.stringify(flutterElements, null, 2));
});