package za.co.reliefroute.reliefroute_backend;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.server.ResponseStatusException;
import za.co.reliefroute.reliefroute_backend.controller.FirestoreCrudController;
import za.co.reliefroute.reliefroute_backend.controller.OrderController;
import za.co.reliefroute.reliefroute_backend.service.FirestoreService;
import za.co.reliefroute.reliefroute_backend.service.ImageService;
import za.co.reliefroute.reliefroute_backend.service.MedicineJdbcService;
import za.co.reliefroute.reliefroute_backend.service.OrderJdbcService;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class SecurityAuthorizationTests {
    @Test
    void patientCannotTrackAnotherPatientsOrder() {
        OrderJdbcService orders = mock(OrderJdbcService.class);
        OrderController controller = new OrderController(orders);
        MockHttpServletRequest request = requestFor("patient-a");
        when(orders.tracking("order-b", "patient-a"))
                .thenThrow(new ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND));

        assertThrows(ResponseStatusException.class, () -> controller.tracking("order-b", request));
        verify(orders).tracking("order-b", "patient-a");
    }

    @Test
    void patientCannotListAnotherPatientsOrders() {
        OrderController controller = new OrderController(mock(OrderJdbcService.class));
        assertThrows(ResponseStatusException.class, () ->
                controller.forUser("patient-b", requestFor("patient-a")));
    }

    @Test
    void patientCannotUseGenericCrudForSensitiveCollections() {
        FirestoreCrudController controller = newController();
        for (String collection : new String[]{"users", "appointments", "prescriptions", "deliveries", "drivers", "pharmacies", "order_items"}) {
            assertThrows(ResponseStatusException.class, () ->
                    controller.list(collection, "", requestFor("patient-a")));
        }
    }

    @Test
    void patientCannotCreateThroughGenericCrud() {
        FirestoreCrudController controller = newController();
        assertThrows(ResponseStatusException.class, () ->
                controller.create("medications", Map.of("userId", "patient-a"), requestFor("patient-a")));
    }

    @Test
    void adminMayUseGenericCrudForControlledOperations() throws Exception {
        FirestoreService db = mock(FirestoreService.class);
        when(db.create(eq("medications"), any())).thenReturn(Map.of("id", "med-1"));
        FirestoreCrudController controller = new FirestoreCrudController(db, mock(ImageService.class), mock(MedicineJdbcService.class));
        MockHttpServletRequest request = requestFor("admin-1");
        request.setAttribute("firebaseClaims", Map.of("role", "admin"));

        assertEquals("med-1", controller.create("medications", Map.of("name", "Paracetamol"), request).get("id"));
        verify(db).create(eq("medications"), any());
    }

    private FirestoreCrudController newController() {
        return new FirestoreCrudController(mock(FirestoreService.class), mock(ImageService.class), mock(MedicineJdbcService.class));
    }

    private MockHttpServletRequest requestFor(String uid) {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setAttribute("firebaseUid", uid);
        return request;
    }
}
