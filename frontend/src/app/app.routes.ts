import { Routes } from '@angular/router';

export const routes: Routes = [
    {
        path: '',
        loadComponent: () => import('./features/vehicle-search/components/vehicle-search-shell/vehicle-search-shell.component').then(m => m.VehicleSearchShellComponent)
    },
    {
        path: '**',
        redirectTo: ''
    }
];
