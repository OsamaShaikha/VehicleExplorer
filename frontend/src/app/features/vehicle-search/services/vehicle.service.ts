import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Make, VehicleType, VehicleModel, ApiResponse } from '../models/vehicle.model';
import { environment } from '../../../../environments/environment';

@Injectable({
    providedIn: 'root'
})
export class VehicleService {
    private http = inject(HttpClient);
    private apiUrl = `${environment.apiUrl}/vehicles`;

    getMakes(): Observable<ApiResponse<Make[]>> {
        return this.http.get<ApiResponse<Make[]>>(`${this.apiUrl}/makes`);
    }

    getVehicleTypes(makeId: number): Observable<ApiResponse<VehicleType[]>> {
        return this.http.get<ApiResponse<VehicleType[]>>(`${this.apiUrl}/makes/${makeId}/vehicle-types`);
    }

    getModels(makeId: number, year: number): Observable<ApiResponse<VehicleModel[]>> {
        let params = new HttpParams().set('year', year.toString());
        return this.http.get<ApiResponse<VehicleModel[]>>(`${this.apiUrl}/makes/${makeId}/models`, { params });
    }
}
