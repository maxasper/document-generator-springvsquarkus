import http from "k6/http";
import { check, sleep } from "k6";

const workload = JSON.parse(open("/workspace/benchmarks/runtime-load-testing-workload.json"));

const baseUrl = __ENV.BASE_URL;
const vus = Number(__ENV.LOAD_TEST_VUS || workload.loadProfile.vus);
const duration = __ENV.LOAD_TEST_DURATION || workload.loadProfile.duration;
const testCase = __ENV.LOAD_TEST_CASE || "mixed";

if (!baseUrl) {
    throw new Error("BASE_URL environment variable is required");
}

if (!["post", "get", "mixed"].includes(testCase)) {
    throw new Error(`Unsupported LOAD_TEST_CASE: ${testCase}. Expected one of: post, get, mixed`);
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

function postGenerate() {
    return http.post(
        `${baseUrl}${workload.endpoints.generate.path}`,
        buildGenerateRequestBody(),
        {
            headers: {
                "Content-Type": workload.endpoints.generate.contentType,
            },
        },
    );
}

function getHistory() {
    return http.get(`${baseUrl}${workload.endpoints.history.path}`);
}

export default function () {
    if (testCase === "post") {
        const generateResponse = postGenerate();
        check(generateResponse, {
            "post returns 200": (response) => response.status === 200,
        });
        return;
    }

    if (testCase === "get") {
        const historyResponse = getHistory();
        check(historyResponse, {
            "get returns 200": (response) => response.status === 200,
        });
        return;
    }

    const generateResponse = postGenerate();
    check(generateResponse, {
        "generate returns 200": (response) => response.status === 200,
    });

    const historyResponse = getHistory();
    check(historyResponse, {
        "history returns 200": (response) => response.status === 200,
    });

    sleep(1);
}
