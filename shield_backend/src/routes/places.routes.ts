import { Router } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import {
  searchPlacesController,
  reverseGeocodeController,
  nearbyPlacesController
} from "../controllers/places.controller";

export const placesRouter = Router();

placesRouter.get("/search", asyncHandler(searchPlacesController));
placesRouter.get("/reverse", asyncHandler(reverseGeocodeController));
placesRouter.get("/nearby", asyncHandler(nearbyPlacesController));
