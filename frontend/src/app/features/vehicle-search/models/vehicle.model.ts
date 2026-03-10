export interface Make {
    makeId: number;
    makeName: string;
}

export interface VehicleType {
    vehicleTypeId: number;
    vehicleTypeName: string;
}

export interface VehicleModel {
    modelId: number;
    modelName: string;
}

export interface ApiResponse<T> {
    success: boolean;
    count: number;
    data: T;
    error?: string;
}
