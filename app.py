import shutil
import subprocess
import os
import csv
import glob
from pprint import pprint
import img2pdf
import sys

from PIL import Image
Image.MAX_IMAGE_PIXELS = 1000000000
# BY_PERIOD_DIR = "by_period"
# BY_SUBJECT_DIR = "by_subject"
DOC_DIR = os.environ['DOC_DIR']
BASE_DIR = f"{DOC_DIR}/new"
TESTS_DIR = f"{DOC_DIR}/tests"
STUDIES_DIR = f"{DOC_DIR}/studies"
INTEGRATED_DIR = f"{DOC_DIR}/integrated"
INTEGRATED_PDF_DIR = f"{DOC_DIR}/integrated_pdf"
METADATAS_DIR = f"{DOC_DIR}/metadatas"

# csv_files = ['./metadatas/test-images-01.csv']

def arabic_to_roman(string):
    table = str.maketrans({
        '1': 'i',
        '2': 'ii',
        '3': 'iii',
        '4': 'iv',
        '5': 'v',
        'Ⅲ': 'iii',
    })
    return string.translate(table)

def full_width_to_half(string):
    return string.translate(str.maketrans({chr(0xFF01 + i): chr(0x21 + i) for i in range(94)}))

def create_filename(row, with_sort_num=False):
    ext = row['src'].split('.')[-1]
    if row['author'] != "":
        author = "{}_".format(row['author'])
    else:
        author = ""
    filename = "{t:}_{y:}_{p:}_{s:}_{a:}{c:}{i:}.{e:}".format(
        t=row['tool_type'],
        y=row['year'],
        p=row['period'],
        s=row['subj'],
        c=row['content_type'],
        a=author,
        i=row['image_index'],
        e=ext,
    )
    return filename

def gen_integrated_unified_name(row):
    if row['tool_type'] == "テスト":
        if row['content_type'] == "問題":
            row['content_type'] = "1問題"
        elif row['content_type'] == "解答なし答案用紙":
            row['content_type'] = "2解答なし答案用紙"
        elif row['content_type'] == "答案":
            row['content_type'] = "3答案"
        elif row['content_type'] == "学生解答":
            row['content_type'] = "4学生解答"
        elif row['content_type'] == "模範解答":
            row['content_type'] = "5模範解答"
        elif row['content_type'] == "解答":
            row['content_type'] = "6解答"


    if row['period'] == "前期中間":
        row['period'] = "1前期中間"
    elif row['period'] == "前期定期":
        row['period'] = "2前期定期"
    elif row['period'] == "後期中間":
        row['period'] = "3後期中間"
    elif row['period'] == "後期定期":
        row['period'] = "4後期定期"

    author = ""
    if row['author'] != "":
        author = " {}".format(row['author'])

    return "{t:} {p:} {y:} {a:}".format(
        t=row['tool_type'], p=row['period'], y=row['year'], a=author)

def make_file_dir(file_path):
    dirs = file_path.split('/')
    dir_path = '/'.join(dirs[:-1])
    os.makedirs(dir_path, exist_ok=True)
    return True
# --------

def get_csv_rows(csv_dir):
    # list all csv files path
    csv_paths = glob.glob("{}/*.csv".format(csv_dir))

    rows = []
    for path in csv_paths:
        with open(path, 'r', encoding="utf_8_sig") as f:
            reader = csv.reader(f)
            header = next(reader)
            # rows.extend(list(reader))
            # append original csv file path
            for row in reader:
                # row.append(path)
                src, subj, tool_type, period, year, content_type, author, image_index, included_pages_num, fix_text = row
                rows.append({
                    'src': src,
                    'subj': subj,
                    'tool_type': tool_type,
                    'period': period,
                    'year': year,
                    'content_type': content_type,
                    'author': author,
                    'image_index': image_index,
                    'included_pages_num': included_pages_num,
                    'fix_text': fix_text,
                    'orig_csv': path,
                })
    return {
        'unassorted': rows
    }

def check_rows(rows):
    invalid_rows = []
    valid_rows = []
    remove_rows = []
    skip_rows = []

    for row in rows['unassorted']:
        if row['subj'] != "" and row['subj'][0] == "い":
            remove_rows.append(row)
            continue

        # 空白チェック
        check_keys = ['subj', 'tool_type', 'period', 'year', 'content_type', 'image_index', 'included_pages_num']
        has_empty = False
        for key in check_keys:
            if row[key] == "":
                skip_rows.append(row)
                has_empty = True
                break
        if has_empty:
            continue

        errors = []

        if not os.path.isfile(f"{DOC_DIR}/{row['src']}"):
            errors.append("source file doesn't exist")

        if row['tool_type'] == "テスト":
            if row['content_type'] != "問題" and row['content_type'] != "解答なし答案用紙" and row['content_type'] != "答案" and row['content_type'] != "学生解答" and row['content_type'] != "模範解答" and row['content_type'] != "解答":
                errors.append("content type is invalid")
        elif row['tool_type'] == "勉強用":
            if row['content_type'] != "ノート" and row['content_type'] != "まとめ" and row['content_type'] != "対策プリント":
                errors.append("content type is invalid")
        else:
            errors.append("tool type is invalid")

        if not row['subj'].isalnum():
            errors.append("subject name is empty")

        if not row['period'].isalpha():
            errors.append("period is empty")
        elif row['period'] != "前期中間" and row['period'] != "前期定期" and row['period'] != "後期中間" and row['period'] != "後期定期":
            errors.append("period is invalid")

        if row['year'] == "不明":
            skip_rows.append(row)
            continue
        elif not row['year'].isnumeric():
            errors.append("year is not numeric")

        # if not row['author'].isalnum() or row['author'] != "":
        #     errors.append("author is invalid")

        if not row['image_index'].isnumeric():
            errors.append("image index is invalid")
        
        if not row['included_pages_num'].isnumeric():
            errors.append("included pages num is invalid")

        # if there is no error.
        if len(errors) == 0:
            row['subj'] = full_width_to_half(row['subj'])
            row['period'] = full_width_to_half(row['period'])
            row['year'] = full_width_to_half(row['year'])
            row['subj'] = arabic_to_roman(row['subj'])
            row['image_index'] = "{:03d}".format(int(full_width_to_half(row['image_index'])))

            valid_rows.append(row)
        else:
            invalid_rows.append({
                'row': row,
                'errors': errors,
            })

    return {
        'unassorted': skip_rows,
        'valid': valid_rows,
        'invalid': invalid_rows,
        'remove': remove_rows,
    }

def assort_rows(rows):
    test_rows = []
    study_rows = []
    remove_rows = rows['remove']
    skip_rows = rows['unassorted']
    for row in rows['valid']:
        if row['fix_text'] == "重複":
            remove_rows.append(row)
        elif row['fix_text'] != "":
            skip_rows.append(row)
        elif row['tool_type'] == "テスト":
            test_rows.append(row)
        elif row['tool_type'] == "勉強用":
            study_rows.append(row)
        # else:
        #     raise Exception("tool type is invalid", row)
    # return test_rows, study_rows, remove_rows, skip_rows
    return {
        'test': test_rows,
        'study': study_rows,
        'remove': remove_rows,
        'unassorted': skip_rows,
    }

def check_conflict(rows):
    check_rows = []
    check_rows.extend(rows['test'])
    check_rows.extend(rows['study'])

    filenames = {}
    conflicts = {}
    
    for row in check_rows:
        filename = create_filename(row)
        # filenames の中になければ追加
        if not filename in filenames:
            filenames[filename] = [row]
        else:
            filenames[filename].append(row)
            # 重複していれば、filenameを重複一覧へ追加
            conflicts[filename] = filenames[filename]

    # 重複がなければ終了
    if len(conflicts) == 0:
        return True, {}
    
    return False, conflicts

def move_file(row, dir):
    dest_filename = create_filename(row)
    new_src = "{d:}/{y:}/{n:}".format(d=dir, y=row['year'], n=dest_filename)

    dest_path = "{b:}/{d:}".format(b=BASE_DIR, d=new_src)
    make_file_dir(dest_path)
    shutil.move(f"{DOC_DIR}/{row['src']}", dest_path)
    row['src'] = new_src
    return row

def move_unchanged_files(src):
    dest = f"{DOC_DIR}/new/{src}"
    make_file_dir(dest)
    shutil.move(f"{DOC_DIR}/{src}", dest)

def gen_csv(rows):
    write_rows = {}
    for row_type, rows in rows.items():
        if row_type != "test" and row_type != "study" and row_type != "unassorted":
            continue

        to_csv_row_keys = [
            # '',
            'subj',
            'tool_type',
            'period',
            'year',
            'content_type',
            'author',
            'image_index',
            'included_pages_num',
            'fix_text',
        ]
        for row in rows:
            if row_type == "test" or row_type == "study":
                write_dest = "metadatas/{}_{}_{}_{}_{}.csv".format(row_type, row['year'], row['period'], row['subj'], row['author'])
                tool_type = "test" if row['tool_type'] == "テスト" else "study"
            else:
                write_dest = f"metadatas/{row['orig_csv'].split('/')[-1]}"
            write_row_values = []
            write_row_values.append(row['src'])
            [write_row_values.append(row[key]) for key in to_csv_row_keys]
            write_row = ",".join(write_row_values)

            if not write_dest in write_rows:
                write_rows[write_dest] = []
            write_rows[write_dest].append(write_row)

    for k, v in write_rows.items():
        dest = f"{DOC_DIR}/new/{k}"
        make_file_dir(dest)
        v.sort()
        v.insert(0, ",".join([key for key in ['src'] + to_csv_row_keys]))
        with open(dest, 'a', encoding="utf_8") as f:
            f.write('\n'.join(v) + "\n")

def remove_alpha_channel(files):
    for image_file in files:
        img = Image.open(image_file)
        if img.mode == "RGBA":
            img.convert("RGB").save()


            
def gen_pdf(rows):
    pdf_lists = {}
    for row in rows:
        if not row['subj'] in pdf_lists:
            pdf_lists[row['subj']] = {}

        unified_name = gen_integrated_unified_name(row) + " " + row['content_type']
        if not unified_name in pdf_lists[row['subj']]:
            pdf_lists[row['subj']][unified_name] = []
        
        pdf_lists[row['subj']][unified_name].append(f"{BASE_DIR}/{row['src']}")

    for subj, set_lists in pdf_lists.items():
        for set_name, files in set_lists.items():
            files.sort()
            image_files = []

            pdf_name = "{i:}/{s:}/{u:}.pdf".format(
                i=INTEGRATED_PDF_DIR, s=subj, u=set_name)

            if len(files) == 1 and files[0].endswith('.pdf'):
                make_file_dir(pdf_name)
                shutil.copy(files[0], pdf_name)
                continue

            files = list(filter(lambda file: file.endswith('.jpg') or file.endswith('.png'), files))

            if len(files) == 0:
                continue

            make_file_dir(pdf_name)
            remove_alpha_channel(files)
            with open(pdf_name, "wb") as f:
                f.write(img2pdf.convert(files, nodate=True))

def gen_symlinks(rows):
    for row in rows:
        # if row['tool_type'] == "テスト":
        #     if row['content_type'] == "問題":
        #         row['content_type'] = "1問題"
        #     elif row['content_type'] == "答案":
        #         row['content_type'] = "2答案"
        #     elif row['content_type'] == "解答":
        #         row['content_type'] = "3解答"
        
        
        # if row['period'] == "前期中間":
        #     row['period'] = "1前期中間"
        # elif row['period'] == "前期定期":
        #     row['period'] = "2前期定期"
        # elif row['period'] == "後期中間":
        #     row['period'] = "3後期中間"
        # elif row['period'] == "後期定期":
        #     row['period'] = "4後期定期"
        unified_name = gen_integrated_unified_name(row)
        filename = create_filename(row)
        integrated_path = "{b:}/{i:}/{s:}/{u:}/{n:}".format(
            b=BASE_DIR, i=INTEGRATED_DIR, s=row['subj'], u=unified_name,
            n=create_filename(row))
        make_file_dir(integrated_path)
        os.symlink("../../../" + row['src'], integrated_path)

def replace_dir():
    replace_dirs = ['scanned', 'studies', 'tests', 'metadatas']
    for dir_ in replace_dirs:
        orig_dir = f"{BASE_DIR}/{dir_}"
        dest_dir = f"{DOC_DIR}/{dir_}"

        if os.path.exists(dest_dir):
            shutil.rmtree(dest_dir)

        if os.path.exists(orig_dir):
            shutil.move(orig_dir, dest_dir)
    os.rmdir(BASE_DIR)


def main():
    rows = get_csv_rows(METADATAS_DIR)
    rows = check_rows(rows)
    if len(rows['invalid']) != 0:
        print("invalid rows:")
        pprint(rows['invalid'])
        sys.exit(1)

    rows = assort_rows(rows)

    is_ok, conflicts = check_conflict(rows)

    if not is_ok:
        print('conflicts:')
        pprint(conflicts)
        sys.exit(1)

    if sys.argv[1] == "check":
        print("ok")
        sys.exit(0)

    rows['test'] = [move_file(test, 'tests') for test in rows['test']]
    rows['study'] = [move_file(study, 'studies') for study in rows['study']]

    [os.remove(row['src']) for row in rows['remove']]
    [move_unchanged_files(row['src']) for row in rows['unassorted']]

    gen_csv(rows)

    if sys.argv[1] == "assort":
        replace_dir()
        print("assorted")
        sys.exit(0)

    if sys.argv[1] == "generate":
        rows_to_gen = rows['study'] + rows['test']
        # pprint(rows_to_gen)
        # gen_symlinks(rows_to_gen)
        gen_pdf(rows_to_gen)
        replace_dir()
        print("generated")

if __name__ == "__main__":
    main()
