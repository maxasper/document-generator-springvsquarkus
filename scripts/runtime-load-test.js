import http from "k6/http";
import { check, sleep } from "k6";

const workload = JSON.parse(open("/workspace/benchmarks/runtime-load-testing-workload.json"));

const baseUrl = __ENV.BASE_URL;
const vus = Number(__ENV.LOAD_TEST_VUS || workload.loadProfile.vus);
const duration = __ENV.LOAD_TEST_DURATION || workload.loadProfile.duration;

if (!baseUrl) {
    throw new Error("BASE_URL environment variable is required");
}

export const options = {
    vus,
    duration,
    thresholds: workload.thresholds,
};

function buildGenerateRequestBody() {
    const suffix = `${Date.now()}-${__VU}-${__ITER}`;

    return JSON.stringify({
        documentFormat: workload.requestTemplate.documentFormat,
        templateType: workload.requestTemplate.templateType,
        documentName: `${workload.requestTemplate.documentNamePrefix}-${suffix}`,
        parameters: {
            customerName: workload.requestTemplate.parameters.customerName,
            invoiceNumber: `${workload.requestTemplate.parameters.invoiceNumberPrefix}-${suffix}`,
            amount: workload.requestTemplate.parameters.amount,
        },
    });
}

export default function () {
    const generateResponse = http.post(
        `${baseUrl}${workload.endpoints.generate.path}`,
        buildGenerateRequestBody(),
        {
            headers: {
                "Content-Type": workload.endpoints.generate.contentType,
            },
        },
    );

    check(generateResponse, {
        "generate returns 200": (response) => response.status === 200,
    });

    const historyResponse = http.get(`${baseUrl}${workload.endpoints.history.path}`);
    check(historyResponse, {
        "history returns 200": (response) => response.status === 200,
    });

    sleep(1);
}
