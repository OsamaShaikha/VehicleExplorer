import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormControl } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatSelectModule } from '@angular/material/select';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatIconModule } from '@angular/material/icon';
import { ScrollingModule } from '@angular/cdk/scrolling';

import { VehicleService } from '../../services/vehicle.service';
import { Make, VehicleModel, VehicleType } from '../../models/vehicle.model';
import { debounceTime, distinctUntilChanged, startWith, map, tap, switchMap, catchError } from 'rxjs/operators';
import { of, BehaviorSubject, combineLatest } from 'rxjs';

@Component({
    selector: 'app-vehicle-search-shell',
    standalone: true,
    imports: [
        CommonModule,
        FormsModule,
        ReactiveFormsModule,
        MatFormFieldModule,
        MatInputModule,
        MatAutocompleteModule,
        MatSelectModule,
        MatCardModule,
        MatChipsModule,
        MatProgressSpinnerModule,
        MatIconModule,
        ScrollingModule
    ],
    templateUrl: './vehicle-search-shell.component.html',
    styleUrls: ['./vehicle-search-shell.component.css']
})
export class VehicleSearchShellComponent implements OnInit {
    private vehicleService = inject(VehicleService);

    makeControl = new FormControl<string | Make>('');
    yearControl = new FormControl<number | null>(null);

    makes = signal<Make[]>([]);
    filteredMakes = signal<Make[]>([]);
    vehicleTypes = signal<VehicleType[]>([]);
    vehicleModels = signal<VehicleModel[]>([]);

    selectedVehicleType = signal<number | null>(null);

    isLoadingMakes = signal<boolean>(false);
    isLoadingResults = signal<boolean>(false);
    errorMessage = signal<string>('');

    years = computed(() => {
        const currentYear = new Date().getFullYear();
        const startYear = 1995;
        return Array.from({ length: currentYear - startYear + 1 }, (_, i) => currentYear - i);
    });

    filteredModels = computed(() => {
        const models = this.vehicleModels();
        const selectedType = this.selectedVehicleType();
        return models;
    });

    ngOnInit() {
        this.loadMakes();

        this.makeControl.valueChanges.pipe(
            startWith(''),
            map(value => typeof value === 'string' ? value : value?.makeName || '')
        ).subscribe(filterValue => {
            this.filterMakes(filterValue);
        });

        combineLatest([
            this.makeControl.valueChanges.pipe(distinctUntilChanged()),
            this.yearControl.valueChanges.pipe(distinctUntilChanged())
        ]).subscribe(([make, year]) => {
            if (typeof make !== 'string' && make?.makeId && year) {
                this.loadVehicleData(make.makeId, year);
            } else {
                this.resetResults();
            }
        });
    }

    displayMakeFn(make: Make): string {
        return make && make.makeName ? make.makeName : '';
    }

    private loadMakes() {
        this.isLoadingMakes.set(true);
        this.vehicleService.getMakes().pipe(
            catchError(err => {
                this.errorMessage.set('Failed to load makes: ' + err.message);
                return of({ success: false, data: [] as Make[], count: 0 });
            })
        ).subscribe(res => {
            if (res.success) {
                this.makes.set(res.data);
                this.filteredMakes.set(res.data);
            }
            this.isLoadingMakes.set(false);
        });
    }

    private filterMakes(value: string) {
        const filterValue = value.toLowerCase();
        const all = this.makes();
        this.filteredMakes.set(
            all.filter(make => make.makeName.toLowerCase().includes(filterValue))
        );
    }

    private loadVehicleData(makeId: number, year: number) {
        this.isLoadingResults.set(true);
        this.errorMessage.set('');

        combineLatest([
            this.vehicleService.getVehicleTypes(makeId).pipe(catchError(err => of({ success: false, data: [] as VehicleType[], count: 0 }))),
            this.vehicleService.getModels(makeId, year).pipe(catchError(err => of({ success: false, data: [] as VehicleModel[], count: 0 })))
        ]).subscribe(([typesRes, modelsRes]) => {
            if (typesRes.success) this.vehicleTypes.set(typesRes.data);
            if (modelsRes.success) this.vehicleModels.set(modelsRes.data);
            if (!typesRes.success || !modelsRes.success) {
                this.errorMessage.set('Error loading vehicle details from API.');
            }
            this.isLoadingResults.set(false);
        });
    }

    private resetResults() {
        this.vehicleTypes.set([]);
        this.vehicleModels.set([]);
        this.selectedVehicleType.set(null);
    }

    selectType(typeId: number) {
        this.selectedVehicleType.update(current => current === typeId ? null : typeId);
    }
}
