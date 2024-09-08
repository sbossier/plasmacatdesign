import logging
import os
os.environ['PDF_SERVICES_CLIENT_ID'] = '7979a1d8027346769c8eb40638c402ba'
os.environ['PDF_SERVICES_CLIENT_SECRET'] = 'p8e-w3yIxnNb3XoQNIkeCChG5AGp55VP9M7P'

from adobe.pdfservices.operation.auth.credentials import Credentials
from adobe.pdfservices.operation.exception.exceptions import ServiceApiException, ServiceUsageException, SdkException
from adobe.pdfservices.operation.pdfops.options.extractpdf.extract_pdf_options import ExtractPDFOptions
from adobe.pdfservices.operation.pdfops.options.extractpdf.extract_element_type import ExtractElementType
from adobe.pdfservices.operation.execution_context import ExecutionContext
from adobe.pdfservices.operation.io.file_ref import FileRef
from adobe.pdfservices.operation.pdfops.extract_pdf_operation import ExtractPDFOperation

logging.basicConfig(level=os.environ.get("LOGLEVEL", "INFO"))

try:
    # Define the file path for your PDF file.
    pdf_file_path = r'C:\Users\sbossier\Desktop\test\output.pdf'

    # Initial setup, create credentials instance.
    credentials = Credentials.service_principal_credentials_builder(). \
        with_client_id(os.getenv('PDF_SERVICES_CLIENT_ID')). \
        with_client_secret(os.getenv('PDF_SERVICES_CLIENT_SECRET')). \
        build()

    # Create an ExecutionContext using credentials and create a new operation instance.
    execution_context = ExecutionContext.create(credentials)
    extract_pdf_operation = ExtractPDFOperation.create_new()

    # Set operation input from a source file.
    source = FileRef.create_from_local_file(pdf_file_path)
    extract_pdf_operation.set_input(source)
#.with_element_to_extract(ExtractElementType.TEXT) \
    # Build ExtractPDF options and set them into the operation
    extract_pdf_options: ExtractPDFOptions = ExtractPDFOptions.builder() \
        .with_element_to_extract(ExtractElementType.TABLES) \
        .build()
    extract_pdf_operation.set_options(extract_pdf_options)

    # Execute the operation.
    result: FileRef = extract_pdf_operation.execute(execution_context)

    # Define the path for the output file.
    output_file_path = os.path.dirname(pdf_file_path) + "/ExtractTextTableInfoFromPDF.zip"

    # Save the result to the specified location.
    result.save_as(output_file_path)
except (ServiceApiException, ServiceUsageException, SdkException):
    logging.exception("Exception encountered while executing operation")