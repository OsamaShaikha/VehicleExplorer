import { Component } from '@angular/core';

@Component({
  selector: 'app-test',
  standalone: true,
  template: `
    <div style="padding: 40px; text-align: center;">
      <h1>🚗 Vehicle Explorer</h1>
      <p>If you see this, the Angular app is working!</p>
      <p>The main component should load here.</p>
    </div>
  `
})
export class TestComponent {}
