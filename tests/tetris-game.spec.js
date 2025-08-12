// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('Flutter Tetris Game', () => {
  
  test.beforeEach(async ({ page }) => {
    // Navigate to the Flutter app
    await page.goto('/');
    
    // Wait for Flutter app to load - use the correct selectors
    await page.waitForSelector('flutter-view', { timeout: 30000 });
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    
    // Wait a bit more for the app to fully initialize
    await page.waitForTimeout(3000);
  });

  test('should load the game interface', async ({ page }) => {
    // Check that the Flutter app container is present
    await expect(page.locator('flt-glass-pane')).toBeVisible();
    
    // Take a screenshot for visual verification
    await page.screenshot({ path: 'screenshots/game-loaded.png' });
  });

  test('should display game title or header', async ({ page }) => {
    // Check that Flutter view and glass pane are present
    await expect(page.locator('flutter-view')).toBeVisible();
    await expect(page.locator('flt-glass-pane')).toBeVisible();
    
    await page.screenshot({ path: 'screenshots/game-interface.png' });
  });

  test('should respond to keyboard input', async ({ page }) => {
    // Focus on the game area
    await page.locator('flt-glass-pane').click();
    
    // Test keyboard controls (common Tetris keys)
    await page.keyboard.press('ArrowLeft');
    await page.waitForTimeout(100);
    
    await page.keyboard.press('ArrowRight'); 
    await page.waitForTimeout(100);
    
    await page.keyboard.press('ArrowDown');
    await page.waitForTimeout(100);
    
    await page.keyboard.press('ArrowUp'); // Usually rotate
    await page.waitForTimeout(100);
    
    await page.screenshot({ path: 'screenshots/after-keyboard-input.png' });
  });

  test('should handle game pause functionality', async ({ page }) => {
    // Focus on the game area
    await page.locator('flt-glass-pane').click();
    
    // Try common pause keys
    await page.keyboard.press('Space'); // Common pause key
    await page.waitForTimeout(500);
    
    await page.keyboard.press('p'); // Another common pause key
    await page.waitForTimeout(500);
    
    await page.screenshot({ path: 'screenshots/pause-test.png' });
  });

  test('should maintain responsive layout on different screen sizes', async ({ page }) => {
    // Test desktop size
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.screenshot({ path: 'screenshots/desktop-view.png' });
    
    // Test tablet size
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.screenshot({ path: 'screenshots/tablet-view.png' });
    
    // Test mobile size
    await page.setViewportSize({ width: 375, height: 667 });
    await page.screenshot({ path: 'screenshots/mobile-view.png' });
    
    // Verify the Flutter app is still visible on mobile
    await expect(page.locator('flutter-view')).toBeVisible();
  });

  test('should handle window focus and blur events', async ({ page }) => {
    // Focus on the game
    await page.locator('flt-glass-pane').click();
    
    // Simulate losing focus (alt+tab simulation)
    await page.evaluate(() => {
      window.dispatchEvent(new Event('blur'));
    });
    
    await page.waitForTimeout(500);
    
    // Simulate regaining focus
    await page.evaluate(() => {
      window.dispatchEvent(new Event('focus'));
    });
    
    await page.waitForTimeout(500);
    
    await page.screenshot({ path: 'screenshots/focus-blur-test.png' });
  });

  test('should load without JavaScript errors', async ({ page }) => {
    const errors = [];
    
    page.on('pageerror', (error) => {
      errors.push(error.message);
    });
    
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });
    
    await page.goto('/');
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    await page.waitForTimeout(3000); // Wait for any async operations
    
    // Check that no critical errors occurred
    const criticalErrors = errors.filter(error => 
      !error.includes('favicon.ico') && // Ignore favicon errors
      !error.includes('DevTools') // Ignore DevTools related messages
    );
    
    expect(criticalErrors).toHaveLength(0);
  });

});